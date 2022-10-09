import { styled } from "uebersicht";

export const Icon = ({ name, size }) => {
  return <Wrapper className={`ti ti-${name}`} size={size} />;
};

const Wrapper = styled.div`
  font-size: ${({ size }) => (size ? `${size}px` : "18px")};
  position: relative;
  top: -1px;
`;
