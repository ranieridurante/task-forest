import {
  getBezierPath,
  Position,
  type ConnectionLineComponentProps,
} from "reactflow";

function ConnectionLine({
  fromX,
  fromY,
  toX,
  toY,
}: ConnectionLineComponentProps) {
  const [path, labelX, labelY, offsetX, offsetY] = getBezierPath({
    sourceX: fromX,
    sourceY: fromY,
    targetX: toX,
    targetY: toY,
  });
  return (
    <>
      <path
        fill="none"
        stroke="#a1a1aa"
        strokeDasharray="5 10"
        strokeWidth={2}
        d={path}
      />
      <circle
        cx={toX}
        cy={toY}
        fill="#fff"
        r={3}
        stroke="#222"
        strokeWidth={1.5}
      />
    </>
  );
}

export default ConnectionLine;
