import { styled } from "uebersicht";
import { theme, toOpacity } from "../utils/theme";

export const BaseBlock = styled.div`
  font-size: 12px;
  background: ${({ accent }) => (accent ? theme.accent : theme.background)};
  color: ${({ accent }) => (accent ? theme.background : theme.text)};
  padding: 0 8px;
  display: flex;
  height: 100%;
  gap: 4px;
  align-items: center;
  transition: 0.2s;
  border-radius: var(--border-radius);
  border: 1px solid ${toOpacity(theme.accent, 0.12)};

  ${({ hoverable }) =>
    hoverable
      ? `&:hover {
    background: ${theme.accent};
  color: ${theme.background}
    }`
      : ""}
`;
