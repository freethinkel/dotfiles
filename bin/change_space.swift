#!/usr/bin/env swift

import Foundation
import CoreGraphics

typealias CGSConnectionID = UInt32
typealias CGSSpaceID = UInt64

@_silgen_name("CGSDefaultConnectionForThread")
func CGSDefaultConnectionForThread() -> CGSConnectionID

@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ cid: CGSConnectionID) -> CFArray?

@_silgen_name("CGSHideSpaces")
func CGSHideSpaces(_ cid: CGSConnectionID, _ spaces: CFArray)

@_silgen_name("CGSShowSpaces")
func CGSShowSpaces(_ cid: CGSConnectionID, _ spaces: CFArray)

@_silgen_name("CGSManagedDisplaySetCurrentSpace")
func CGSManagedDisplaySetCurrentSpace(_ cid: CGSConnectionID, _ displayUUID: CFString, _ spaceID: CGSSpaceID)

@_silgen_name("CGSDisableUpdate")
func CGSDisableUpdate(_ cid: CGSConnectionID)

@_silgen_name("CGSReenableUpdate")
func CGSReenableUpdate(_ cid: CGSConnectionID)

let cid = CGSDefaultConnectionForThread()

guard let rawDisplays = CGSCopyManagedDisplaySpaces(cid) as? [[String: Any]],
      let display = rawDisplays.first,
      let displayUUID = display["Display Identifier"] as? String,
      let spaceDicts = display["Spaces"] as? [[String: Any]],
      let currentSpaceDict = display["Current Space"] as? [String: Any],
      let currentSpace = currentSpaceDict["id64"] as? CGSSpaceID else {
    print("Could not read display spaces")
    exit(1)
}

let spaces = spaceDicts.compactMap { $0["id64"] as? CGSSpaceID }

let targetIndex = Int(CommandLine.arguments.dropFirst().first ?? "1")! - 1
guard targetIndex < spaces.count else {
    print("Space \(targetIndex + 1) doesn't exist. You have \(spaces.count) spaces.")
    exit(1)
}

let targetSpace = spaces[targetIndex]

guard currentSpace != targetSpace else {
    print("Already on space \(targetIndex + 1)")
    exit(0)
}

CGSDisableUpdate(cid)
CGSShowSpaces(cid, [targetSpace] as CFArray)
CGSManagedDisplaySetCurrentSpace(cid, displayUUID as CFString, targetSpace)
CGSHideSpaces(cid, [currentSpace] as CFArray)
CGSReenableUpdate(cid)

DistributedNotificationCenter.default().postNotificationName(
    NSNotification.Name("com.apple.spaces.didchangeactivespace"),
    object: nil,
    userInfo: nil,
    deliverImmediately: true
)

print("Switched to space \(targetIndex + 1) (id: \(targetSpace))")
