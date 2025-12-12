import React, { useState, useEffect } from 'react'
import {
  Button,
  Modal,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalFooter,
  Switch,
  Table,
  TableBody,
  TableCell,
  TableColumn,
  TableHeader,
  TableRow,
  Tooltip,
} from '@nextui-org/react'
import { intlFormatDistance } from 'date-fns'
import type { TScheduledTrigger, TScheduledTriggersTableProps } from 'types/app'
import cronstrue from 'cronstrue'
import {
  addLiveViewEventListener,
  removeLiveViewEventListener,
} from '../../util'

const STATUS_OPTIONS = [
  { key: 'active', label: 'Active', color: 'success' },
  { key: 'not_active', label: 'Not Active', color: 'danger' },
] as const

/**
 * Component that represents a table of scheduled triggers.
 * @constructor
 */
const ScheduledTriggersTable: React.FC<TScheduledTriggersTableProps> = ({
  scheduledTriggers,
  pushEvent,
  onOpenExecutionModal,
  onOpenInputOutputModal,
}) => {
  const [data, setData] = useState<TScheduledTrigger[]>(scheduledTriggers || [])

  /**
   * Function responsible for changing the state of a scheduled trigger.
   * @param triggerId Scheduled trigger ID.
   * @param newStatus New status value.
   */
  const handleStatusChange = (triggerId: string, newStatus: string) => {
    const updatedData = data.map((item) =>
      item.id === triggerId ? { ...item, active: newStatus === 'active' } : item
    )
    setData(updatedData)
    pushEvent('react.update_scheduled_trigger_status', {
      id: triggerId,
      active: newStatus === 'active',
    })
  }

  /**
   * Function responsible for deleting a scheduled trigger.
   * @param triggerId Scheduled trigger ID.
   */
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false)
  const [triggerToDelete, setTriggerToDelete] = useState<string | null>(null)

  const onDeleteTriggerButtonClick = (triggerId: string) => {
    setTriggerToDelete(triggerId)
    setIsDeleteModalOpen(true)
  }

  const handleDeleteConfirm = () => {
    if (triggerToDelete) {
      setData((prevData) =>
        prevData.filter((item) => item.id !== triggerToDelete)
      )
      pushEvent('react.delete_scheduled_trigger', {
        scheduled_trigger_id: triggerToDelete,
      })
    }
    setIsDeleteModalOpen(false)
    setTriggerToDelete(null)
  }

  const handleDeleteCancel = () => {
    setIsDeleteModalOpen(false)
    setTriggerToDelete(null)
  }

  useEffect(() => {
    const onTriggerUpdate: LiveViewEventCallback<
      'server.scheduled_trigger_updated'
    > = (trigger) => {
      const existingTriggerIndex = data.findIndex((t) => t.id === trigger.id)
      if (existingTriggerIndex >= 0) {
        data[existingTriggerIndex] = trigger
      } else {
        data.unshift(trigger)
      }
      setData(structuredClone(data))
    }

    addLiveViewEventListener(
      'server.scheduled_trigger_updated',
      onTriggerUpdate
    )
    return () =>
      removeLiveViewEventListener(
        'server.scheduled_trigger_updated',
        onTriggerUpdate
      )
  }, [])

  useEffect(() => {
    const onTriggerCreation: LiveViewEventCallback<
      'server.scheduled_trigger_created'
    > = (trigger) => {
      if (trigger) {
        setData([trigger, ...data])
      }
    }

    addLiveViewEventListener(
      'server.scheduled_trigger_created',
      onTriggerCreation
    )
    return () =>
      removeLiveViewEventListener(
        'server.scheduled_trigger_created',
        onTriggerCreation
      )
  }, [])

  return (
    <>
      <div className='flex mb-2 items-center mt-4'>
        <iconify-icon
          className='text-plombDarkBrown-500 mr-2 self-center'
          icon='tabler:calendar-bolt'
          width='24'
          height='24'
        />
        <p className='text-lg grow ml-2'>Scheduled Triggers</p>
        <Button
          className='justify-self-end bg-plombPink-500 mb-2'
          color='primary'
          onPress={() => onOpenExecutionModal(null)}
          startContent={
            <iconify-icon
              icon='fluent-mdl2:trigger-auto'
              width='20'
              height='20'
            />
          }
        >
          Schedule New Trigger
        </Button>
      </div>
      <Table isStriped aria-label='Scheduled triggers'>
        <TableHeader>
          <TableColumn>
            <div className='flex flex-row items-center'>
              <iconify-icon
                class='mr-1'
                icon='tabler:id'
                width='14'
                height='14'
              />
              <p className='text-md'>Name</p>
            </div>
          </TableColumn>
          <TableColumn>
            <div className='flex flex-row items-center'>
              <iconify-icon
                class='mr-1'
                icon='mdi:clock-time-four-outline'
                width='14'
                height='14'
              />
              <p className='text-md'>Schedule</p>
            </div>
          </TableColumn>
          <TableColumn>
            <div className='flex flex-row items-center'>
              <iconify-icon
                class='mr-1'
                icon='fa-solid:cogs'
                width='14'
                height='14'
              />
              <p className='text-md'>Active</p>
            </div>
          </TableColumn>
          <TableColumn>
            <div className='flex flex-row items-center'>
              <iconify-icon
                class='mr-1'
                icon='material-symbols:settings'
                width='14'
                height='14'
              />
              <p className='text-md'>Actions</p>
            </div>
          </TableColumn>
        </TableHeader>
        <TableBody items={data} emptyContent='No scheduled triggers found.'>
          {(item) => (
            <TableRow key={item.id}>
              <TableCell>
                <p className='font-bold'>{item.name}</p>
              </TableCell>
              <TableCell>
                <div>
                  <p>
                    {cronstrue.toString(item.cron_expression, {
                      use24HourTimeFormat: true,
                      verbose: true,
                    })}
                  </p>
                  <span className='text-gray-400 font-mono'>
                    {item.cron_expression}
                  </span>
                </div>
              </TableCell>
              <TableCell>
                <Switch
                  size='sm'
                  defaultSelected={item.active}
                  color='success'
                  onChange={(e) =>
                    handleStatusChange(
                      item.id,
                      e.target.checked ? 'active' : 'not_active'
                    )
                  }
                />
              </TableCell>
              <TableCell>
                <div className='flex items-center gap-2'>
                  <Tooltip content='Edit trigger' closeDelay={0}>
                    <iconify-icon
                      class='cursor-pointer text-plombDarkBrown-500'
                      icon='clarity:edit-solid'
                      width='22'
                      height='22'
                      onClick={() => onOpenExecutionModal(item)}
                    />
                  </Tooltip>
                  <Tooltip content='Delete trigger' closeDelay={0}>
                    <iconify-icon
                      class='cursor-pointer text-red-500'
                      icon='fluent:delete-16-filled'
                      width='22'
                      height='22'
                      onClick={() => onDeleteTriggerButtonClick(item.id)}
                    />
                  </Tooltip>
                </div>
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
      <Modal isOpen={isDeleteModalOpen} onClose={handleDeleteCancel} size='sm'>
        <ModalContent>
          <ModalHeader>Confirm Delete</ModalHeader>
          <ModalBody>Are you sure you want to delete this trigger?</ModalBody>
          <ModalFooter>
            <Button color='danger' onPress={handleDeleteConfirm}>
              Delete
            </Button>
            <Button color='default' onPress={handleDeleteCancel}>
              Cancel
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </>
  )
}

export default ScheduledTriggersTable
