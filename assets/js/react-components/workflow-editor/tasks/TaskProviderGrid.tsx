import type { TTaskProvider, TTaskProviderGridProps } from 'types/task'
import { Button } from '@nextui-org/react'
import React from 'react'

/**
 * Component that represents a list of providers.
 * @constructor
 */
const TaskProviderGrid: React.FC<TTaskProviderGridProps> = ({ taskProviders, onTaskProviderSelect }) => {
  // TODO SearchBar
  // TODO Featured Providers
  return (
    <div
      key="TaskProviderGrid"
      className="gap-2 grid grid-cols-4"
    >
      {Array.from(taskProviders.values()).map((task: TTaskProvider) => (
        <Button
          className="justify-start text-white text-lg font-bold px-3"
          key={task.slug}
          onPress={() => onTaskProviderSelect(task.slug)}
          style={{
            backgroundColor: task.style.background_color,
          }}
          variant="solid"
          size="lg"
          radius="sm"
          startContent={(
            <iconify-icon
              width="28"
              height="28"
              icon={task.style.icon}
              style={{
                color: task.style.icon_color ?? 'white',
              }}
            />
          )}
        >
          {task.name}
        </Button>

      ))}
    </div>
  )
}

export default TaskProviderGrid
