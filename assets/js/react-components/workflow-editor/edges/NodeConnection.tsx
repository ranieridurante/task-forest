import React, { useState } from 'react'
import {
  BaseEdge,
  EdgeLabelRenderer,
  type EdgeProps,
  getBezierPath,
  Position,
} from 'reactflow'
import { Button, Tooltip } from '@nextui-org/react'
import type { TEdgeData } from 'types/workflow'
import { humanizeString } from '../../../utils'

const NodeConnection: React.FC<EdgeProps<TEdgeData>> = ({
  id,
  sourceX,
  sourceY,
  targetX,
  targetY,
  source,
  target,
  data,
  ...props
}) => {
  const [edgePath, labelX, labelY] = getBezierPath({
    sourceX,
    sourceY,
    targetX,
    targetY,
    sourcePosition: Position.Right,
    targetPosition: Position.Left,
    curvature: 0.2,
  })

  const [isNear, setIsNear] = useState(false)

  const handleMouseEnter = () => {
    setIsNear(true)
  }

  const handleMouseLeave = () => {
    setIsNear(false)
  }

  return (
    <>
      <BaseEdge id={id} path={edgePath} {...props} />
      <EdgeLabelRenderer>
        {data?.filter && (
          <div
            style={{
              position: 'absolute',
              transform: `translate(-50%, -50%) translate(${labelX}px,${labelY}px)`,
              width: '200px',
              height: '100px',
              pointerEvents: 'all',
            }}
          >
            <Tooltip
              closeDelay={0}
              content={
                <div className='p-2 text-center'>
                  <p>{data?.filter.variable_key}</p>
                  <p className='text-uppercase font-bold'>
                    {humanizeString(data?.filter.comparison_condition)}
                  </p>
                  <p>{data?.filter.comparison_value}</p>
                </div>
              }
            >
              <Button
                style={{
                  position: 'absolute',
                  transform: `translate(125%, 50%)`,
                  pointerEvents: 'all',
                }}
                disableAnimation
                className='nodrag nopan absolute'
                onClick={() => data?.onEditFilterButtonClick(data?.filter)}
                isIconOnly
                color='success'
                variant='solid'
                radius='full'
                size='lg'
                aria-label='Add Filter'
              >
                <iconify-icon
                  icon='mdi:filter'
                  width='24'
                  height='24'
                  color='primary'
                />
              </Button>
            </Tooltip>
          </div>
        )}
        {!data?.filter && (
          <div
            style={{
              position: 'absolute',
              transform: `translate(-50%, -50%) translate(${labelX}px,${labelY}px)`,
              width: '200px',
              height: '100px',
              pointerEvents: 'all',
            }}
            onMouseEnter={handleMouseEnter}
            onMouseLeave={handleMouseLeave}
          >
            <Tooltip closeDelay={0} content='Delete Connection'>
              <Button
                style={{
                  position: 'absolute',
                  transform: `translate(120%, 85%)`,
                  pointerEvents: 'all',
                }}
                disableAnimation
                className={`nodrag nopan ${isNear ? 'absolute' : 'hidden'}`}
                onClick={() => data?.onRemoveEdgeButtonClick(source, target)}
                isIconOnly
                color='danger'
                variant='ghost'
                radius='full'
                size='sm'
                aria-label='Disconnect'
              >
                <iconify-icon
                  icon='mdi:cancel-bold'
                  width='16'
                  height='16'
                  color='primary'
                />
              </Button>
            </Tooltip>
            <Tooltip closeDelay={0} content='Add Filter'>
              <Button
                style={{
                  position: 'absolute',
                  transform: `translate(325%, 85%)`,
                  pointerEvents: 'all',
                }}
                disableAnimation
                className={`nodrag nopan ${isNear ? 'absolute' : 'hidden'}`}
                onClick={() => data?.onAddFilterButtonClick(source, target)}
                isIconOnly
                color='success'
                variant='ghost'
                radius='full'
                size='sm'
                aria-label='Add Filter'
              >
                <iconify-icon
                  icon='mdi:filter-plus'
                  width='16'
                  height='16'
                  color='primary'
                />
              </Button>
            </Tooltip>
          </div>
        )}
      </EdgeLabelRenderer>
    </>
  )
}

export default NodeConnection
