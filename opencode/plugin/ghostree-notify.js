// Ghostree opencode plugin v5
/**
 * Ghostree notification plugin for OpenCode.
 *
 * Only active when run inside Ghostree (checks GHOSTREE_AGENT_EVENTS_DIR).
 * Emits Start/Stop/PermissionRequest events by appending to agent-events.jsonl.
 */
import fs from "node:fs";
import path from "node:path";

export const GhostreeNotifyPlugin = async ({ client, directory, worktree }) => {
  if (globalThis.__ghostreeOpencodeNotifyPluginV5) return {};
  globalThis.__ghostreeOpencodeNotifyPluginV5 = true;

  const eventsDir = process?.env?.GHOSTREE_AGENT_EVENTS_DIR;
  if (!eventsDir) return {};
  const logPath = path.join(eventsDir, "agent-events.jsonl");
  const debugPath = path.join(eventsDir, "agent-events-debug.jsonl");
  const baseCwd = worktree || directory || process.cwd();
  let lastKnownCwd = baseCwd;

  const resolveCwd = (event) => {
    const props = event?.properties ?? {};
    return (
      props.directory ??
      props.cwd ??
      props.path ??
      props.worktree ??
      props.info?.directory ??
      props.info?.cwd ??
      props.info?.path ??
      null
    );
  };

  const updateCwd = (event) => {
    const eventCwd = resolveCwd(event);
    if (eventCwd && eventCwd !== "/") {
      lastKnownCwd = eventCwd;
    }
  };

  const append = (eventType, event) => {
    try {
      fs.mkdirSync(eventsDir, { recursive: true });
      const payload = {
        timestamp: new Date().toISOString(),
        eventType,
        cwd: resolveCwd(event) ?? lastKnownCwd ?? baseCwd ?? process.cwd(),
      };
      fs.appendFileSync(logPath, JSON.stringify(payload) + "\n");
    } catch {
      // Best-effort only
    }
  };

  const debug = (kind, event, extra = {}) => {
    try {
      fs.mkdirSync(eventsDir, { recursive: true });
      const payload = {
        timestamp: new Date().toISOString(),
        kind,
        cwd: lastKnownCwd ?? baseCwd ?? process.cwd(),
        eventType: event?.type ?? null,
        properties: event?.properties ?? null,
        ...extra,
      };
      fs.appendFileSync(debugPath, JSON.stringify(payload) + "\n");
    } catch {
      // Best-effort only
    }
  };

  let currentState = "idle"; // 'idle' | 'busy'
  let rootSessionID = null;
  let stopSent = false;

  const childSessionCache = new Map();
  const isChildSession = async (sessionID) => {
    if (!sessionID) return false;
    if (!client?.session?.list) return false;
    if (childSessionCache.has(sessionID)) return childSessionCache.get(sessionID);
    try {
      const sessions = await client.session.list();
      const session = sessions.data?.find((s) => s.id === sessionID);
      const isChild = !!(session?.parentID ?? session?.parentId ?? session?.parent_id);
      childSessionCache.set(sessionID, isChild);
      return isChild;
    } catch {
      return false;
    }
  };

  const normalizeSessionID = (sessionID) => sessionID ?? "unknown";

  const getSessionID = (event) => {
    const props = event?.properties ?? {};
    return props.sessionID ?? props.sessionId ?? props.session_id ?? props.session ?? props.id ?? null;
  };

  const handleBusy = async (sessionID, event) => {
    const sid = normalizeSessionID(sessionID);
    if (!rootSessionID) rootSessionID = sid;
    if (sid !== rootSessionID) return;
    if (currentState === "idle") {
      currentState = "busy";
      stopSent = false;
      append("Start", event);
    }
  };

  const handleStop = async (sessionID, event) => {
    if (!sessionID && currentState === "busy" && !stopSent) {
      currentState = "idle";
      stopSent = true;
      append("Stop", event);
      rootSessionID = null;
      return;
    }
    const sid = normalizeSessionID(sessionID);
    if (rootSessionID && sid !== rootSessionID) return;
    if (currentState === "busy" && !stopSent) {
      currentState = "idle";
      stopSent = true;
      append("Stop", event);
      rootSessionID = null;
    }
  };

  return {
    event: async ({ event }) => {
      const sessionID = getSessionID(event);
      updateCwd(event);

      if (await isChildSession(sessionID)) return;

      if (event.type === "session.status") {
        const status = event.properties?.status;
        if (status?.type === "busy") await handleBusy(sessionID, event);
        if (status?.type === "idle") await handleStop(sessionID, event);
        if (status?.type !== "busy" && status?.type !== "idle") {
          debug("unhandled_status_type", event, { statusType: status?.type ?? null });
        }
        return;
      }

      if (event.type === "session.idle") {
        await handleStop(sessionID, event);
        return;
      }
      if (event.type === "session.error") {
        await handleStop(sessionID, event);
        return;
      }
      if (event.type === "server.instance.disposed") {
        await handleStop(sessionID, event);
        return;
      }

      debug("unhandled_event_type", event);
    },
    "permission.ask": async (_permission, output) => {
      if (output.status === "ask") append("PermissionRequest");
    },
  };
};

export default GhostreeNotifyPlugin;