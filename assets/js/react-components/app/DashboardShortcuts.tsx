import React from 'react'
import { Tooltip } from '@nextui-org/react'

interface DashboardShortcut {
  name: string
  link: string
  icon: string
  description: string
  data?: string
}

interface DashboardShortcutsProps {
  shortcuts: DashboardShortcut[]
}

const DashboardShortcuts: React.FC<DashboardShortcutsProps> = ({
  shortcuts,
}) => {
  return (
    <div className='my-4 mb-12 px-1'>
      <div className='flex flex-row items-center mb-4'>
        <iconify-icon
          icon='material-symbols:dashboard-customize'
          width='22'
          height='22'
        />
        <h2 className='text-xl grow ml-2'>Shortcuts</h2>
      </div>

      <div className='flex flex-row flex-wrap gap-4 w-full'>
        {shortcuts.map((shortcut) => (
          <Tooltip
            key={shortcut.name}
            content={shortcut.description}
            placement='top'
            className='max-w-[200px]'
          >
            <a
              href={shortcut.link}
              className='flex items-center justify-center bg-white rounded-xl shadow-sm border aspect-square w-full max-w-[150px] hover:shadow-md transition-shadow duration-200'
            >
              <div className='flex flex-col justify-center items-center gap-1'>
                <iconify-icon
                  icon={shortcut.icon}
                  width='32'
                  height='32'
                  class='text-plombPink-500 fill-plombPink-500 my-1'
                />
                <div className='text-base font-semibold text-plombLightBrown-400 text-center'>
                  {shortcut.name}
                </div>
                {shortcut.data && (
                  <div className='text-xs text-gray-500'>{shortcut.data}</div>
                )}
              </div>
            </a>
          </Tooltip>
        ))}
      </div>
    </div>
  )
}

export default DashboardShortcuts
