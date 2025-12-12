import type { Key } from 'react'
import React from 'react'
import {
  Button,
  Dropdown,
  DropdownItem,
  DropdownMenu,
  DropdownSection,
  DropdownTrigger,
  Tooltip,
} from '@nextui-org/react'
import WorkflowAction from './model/WorkflowAction'

/**
 * Workflow tools dropdown properties
 */
type WorkflowToolsDropdownProps = {
  onDropdownActionSelected: (key: Key) => void
}

/**
 * Component that represents a menu of workflow tools.
 * @param onDropdownActionSelected
 * @constructor
 */
const WorkflowToolsDropdown: React.FC<WorkflowToolsDropdownProps> = ({
  onDropdownActionSelected,
}) => {
  return (
    <Dropdown type='listbox' placement='top-start' showArrow backdrop='opaque'>
      <Tooltip
        placement='right'
        content='Workflow tools'
        radius='sm'
        closeDelay={0}
      >
        <div>
          <DropdownTrigger>
            <Button
              isIconOnly
              size='lg'
              color='primary'
              className='bg-plombPink-500 rounded-md'
              startContent={
                <iconify-icon icon='formkit:tools' width='32' height='32' />
              }
              variant='solid'
              onMouseOver={(e) => e.currentTarget.click()}
            ></Button>
          </DropdownTrigger>
        </div>
      </Tooltip>
      <DropdownMenu
        aria-label='Action event example'
        onAction={onDropdownActionSelected}
      >
        <DropdownSection title='Add a new element' showDivider>
          <DropdownItem
            key={WorkflowAction.ADD_TASK}
            description='Give your workflow a new skill!'
            startContent={
              <iconify-icon icon='jam:task-list-f' width='24' height='24' />
            }
          >
            New Task
          </DropdownItem>
          <DropdownItem
            key={WorkflowAction.ADD_CONVERGER}
            description='Bringing together the results of tasks that work side by side'
            startContent={
              <iconify-icon
                icon='material-symbols-light:database'
                width='24'
                height='24'
              />
            }
          >
            New Converger
          </DropdownItem>
          <DropdownItem
            key={WorkflowAction.ADD_ITERATOR}
            description='Takes care of each item on your list, one by one'
            startContent={
              <iconify-icon icon='mdi:reiterate' width='24' height='24' />
            }
          >
            New List Processor
          </DropdownItem>
        </DropdownSection>
        <DropdownSection title='Workflow options'>
          <DropdownItem
            key={WorkflowAction.ORGANIZE_CANVAS}
            description='Click here to refresh and tidy up your Canvas for a cleaner look!'
            startContent={
              <iconify-icon icon='mingcute:broom-line' width='24' height='24' />
            }
          >
            Organize Canvas
          </DropdownItem>
          <DropdownItem
            key={WorkflowAction.EDIT_APP}
            description='Edit the data slots displayed in your app.'
            startContent={
              <iconify-icon
                icon='mdi:application-edit'
                width='24'
                height='24'
              />
            }
          >
            Edit App Definition
          </DropdownItem>
          <DropdownItem
            key={WorkflowAction.APP_DASHBOARD}
            description='Access the workflow dashboard to monitor performance and schedule triggers.'
            startContent={
              <iconify-icon icon='mdi:graph-line' width='24' height='24' />
            }
          >
            Dashboard
          </DropdownItem>
          <DropdownItem
            key={WorkflowAction.PLAYGROUND}
            description='Test the workflow with any input and see its execution in the debugging console.'
            startContent={
              <iconify-icon icon='grommet-icons:test' width='24' height='24' />
            }
          >
            Playground
          </DropdownItem>
        </DropdownSection>
      </DropdownMenu>
    </Dropdown>
  )
}

export default WorkflowToolsDropdown
