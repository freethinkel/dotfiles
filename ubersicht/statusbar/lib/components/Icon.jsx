import { styled } from "uebersicht";

export const Icon = ({ name }) => {
  return <StyledIcon className={`ti ti-${name}`} />;
};

const StyledIcon = styled.span``;
