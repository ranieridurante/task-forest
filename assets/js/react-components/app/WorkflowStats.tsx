import React from 'react'
import type { TWorkflowStatsProps } from 'types/app'
import { Chip } from '@nextui-org/react'

const WorkflowStats: React.FC<TWorkflowStatsProps> = ({
  executionTime,
  totalExecutions,
  activeTriggers,
}) => {
  return (
    <div className='my-4 px-1'>
      <div className='flex flex-row items-center mb-4'>
        <iconify-icon
          icon='streamline:good-health-and-well-being-remix'
          width='22'
          height='22'
        />
        <h2 className='text-xl grow ml-2'>Workflow Stats</h2>
      </div>

      <div className='grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 w-full'>
        {[
          {
            label: 'Total Executions',
            value: totalExecutions || 0,
            icon: 'carbon:batch-job',
          },
          {
            label: 'Avg Duration',
            value: `${executionTime || 0}s`,
            icon: 'ic:outline-timer',
          },
          /* NOTE: disabled until we calculate credits for each run */
          {
            label: 'Active Triggers',
            value: activeTriggers || 0,
            icon: 'tabler:calendar-bolt',
          },
        ].map(({ label, value, icon }) => (
          <div
            key={label}
            className='flex items-center justify-between bg-white rounded-xl shadow-sm border px-6 py-4 w-full max-w-sm'
          >
            <div className='flex flex-col justify-center items-center gap-1 flex-1'>
              <iconify-icon
                icon={icon}
                width='44'
                height='44'
                class='text-plombPink-500 fill-plombPink-500 my-1'
              />
              <Chip
                size='sm'
                variant='flat'
                radius='full'
                className='text-sm text-white bg-plombPink-500 uppercase'
              >
                {label}
              </Chip>
              <div className='text-2xl font-bold text-plombLightBrown-400'>
                {value}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

export default WorkflowStats
