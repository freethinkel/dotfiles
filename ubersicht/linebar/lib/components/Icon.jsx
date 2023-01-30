import { styled } from "uebersicht";

export const Icon = ({ name, size }) => {
  return <Wrapper className={`icon ti ti-${name}`} size={size} />;
};

const Wrapper = styled.div`
  font-size: ${({ size }) => (size ? `${size}px` : "18px")};
  position: relative;
  top: -2px;
`;
