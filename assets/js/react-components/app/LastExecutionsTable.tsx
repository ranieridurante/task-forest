import React, { useCallback, useEffect, useMemo, useState } from 'react'
import {
  Button,
  Chip,
  Pagination,
  Spinner,
  Table,
  TableBody,
  TableCell,
  TableColumn,
  TableHeader,
  TableRow,
  Tooltip,
  Select,
  SelectItem,
  Spacer,
} from '@nextui-org/react'
import { intlFormatDistance } from 'date-fns'
import JSONTooltip from './popup/JSONTooltip'
import {
  addLiveViewEventListener,
  removeLiveViewEventListener,
} from '../../util'
import type {
  TExecution,
  TExecutionStatus,
  TLastExecutionsTableProps,
} from 'types/app'

const TABLE_ROWS_PER_PAGE = 5
const DEFAULT_COST = '$100'
const STATUS_OPTIONS = [
  { key: 'completed', label: 'Completed', color: 'success' },
  { key: 'cancelled', label: 'Cancelled', color: 'danger' },
  { key: 'started', label: 'Started', color: 'primary' },
  { key: 'delayed', label: 'Delayed', color: 'warning' },
  { key: 'pending', label: 'Pending', color: 'default' },
] as const

const LastExecutionsTable: React.FC<TLastExecutionsTableProps> = ({
  executions,
  totalExecutions,
  pushEvent,
  onOpenExecutionModal,
  onOpenInputOutputModal,
  workflow_id,
}) => {
  const [data, setData] = useState<TExecution[]>(executions)
  const [page, setPage] = useState(1)
  const [loadingState, setLoadingState] = useState<'idle' | 'loading'>('idle')
  const [error, setError] = useState<string | null>(null)

  const items = useMemo(() => {
    const start = (page - 1) * TABLE_ROWS_PER_PAGE
    const end = start + TABLE_ROWS_PER_PAGE
    return data.slice(start, end)
  }, [page, data])

  const pages = useMemo(
    () => Math.ceil(totalExecutions / TABLE_ROWS_PER_PAGE),
    [data.length]
  )

  const onPageChange = (newPage: number) => {
    if (newPage != page) {
      pushEvent('react.retrieve_executions', {
        workflow_id,
        page: newPage,
        page_size: TABLE_ROWS_PER_PAGE,
      })
      setLoadingState('loading')
      setPage(newPage)
    }
  }

  const onRepeatExecutionButtonClick = (execution_id: string) => {
    pushEvent('react.dashboard_repeat_execution', { execution_id })
  }

  useEffect(() => {
    /**
     * Callback executed when the server sends an execution update.
     */
    const onExecutionUpdate: LiveViewEventCallback<
      'server.execution_update'
    > = ({ execution }) => {
      const existingExecutionIndex = data.findIndex(
        (e) => e.id === execution.id
      )
      if (existingExecutionIndex >= 0) {
        data[existingExecutionIndex] = execution
      } else {
        data.unshift(execution)
      }

      setData(structuredClone(data))
    }

    addLiveViewEventListener('server.execution_update', onExecutionUpdate)
    return removeLiveViewEventListener(
      'server.execution_update',
      onExecutionUpdate
    )
  }, [])

  useEffect(() => {
    /**
     * Callback executed when the server sends an executions page.
     */
    const onExecutionsRetrieved: LiveViewEventCallback<
      'server.executions_retrieved'
    > = ({ executions, page, page_size }) => {
      data.splice((page - 1) * page_size, page_size, ...executions)
      setData(structuredClone(data))
      setLoadingState('idle')
    }

    addLiveViewEventListener(
      'server.executions_retrieved',
      onExecutionsRetrieved
    )
    return removeLiveViewEventListener(
      'server.executions_retrieved',
      onExecutionsRetrieved
    )
  }, [])

  const handleCancelExecution = (executionId: string) => {
    pushEvent('react.dashboard_cancel_execution', {
      execution_id: executionId,
    })
  }

  const handleUpdateTable = () => {
    pushEvent('react.retrieve_executions', {
      workflow_id: workflow_id,
      page: page,
      page_size: TABLE_ROWS_PER_PAGE,
    })
  }

  if (error) {
    return <div className='text-danger'>{error}</div>
  }

  return (
    <div className='my-20'>
      <div className='flex flex-row justify-beetween mb-4 items-center mt-4 px-1'>
        <div className='flex flex-row items-center'>
          <iconify-icon icon='solar:history-linear' width='22' height='22' />
          <h2 className='text-xl grow ml-2'>Execution History</h2>
        </div>
        <div className='flex flex-row items-center gap-2 ml-auto'>
          <Tooltip content='Update list' closeDelay={0}>
            <iconify-icon
              class='cursor-pointer text-green-500 mr-2'
              icon='mdi:sync'
              width='24'
              height='24'
              onClick={(e) => {
                handleUpdateTable()
              }}
            />
          </Tooltip>
          {/* NOTE: hidden Stats button */}
          <Button
            size='sm'
            variant='bordered'
            className='text-[#4B2E2E] border-[#4B2E2E] hidden'
            startContent={
              <iconify-icon
                icon='material-symbols:monitoring'
                width='16'
                height='16'
              />
            }
          >
            Statistics
          </Button>
          <Button
            color='primary'
            className='bg-plombPink-500'
            onPress={() =>
              window.open(`/workflows/${workflow_id}/playground`, '_blank')
            }
            startContent={
              <iconify-icon icon='grommet-icons:test' width='16' height='16' />
            }
          >
            Test in Playground
          </Button>
        </div>
      </div>

      <Table
        isStriped
        classNames={{
          wrapper: 'bg-white',
        }}
        aria-label='Last Executions'
        bottomContent={
          pages > 0 ? (
            <div className='flex w-full justify-center'>
              <Pagination
                isCompact
                showControls
                showShadow
                color='primary'
                page={page}
                total={pages}
                onChange={onPageChange}
              />
            </div>
          ) : null
        }
      >
        <TableHeader>
          <TableColumn>
            <div className='flex flex-row items-center'>
              <iconify-icon
                class='mr-1'
                icon='f7:number'
                width='14'
                height='14'
              />
              <p className='text-md'>Execution ID</p>
            </div>
          </TableColumn>
          <TableColumn>
            <div className='flex flex-row items-center'>
              <iconify-icon
                class='mr-1'
                icon='material-symbols:calendar-month'
                width='14'
                height='14'
              />
              <p className='text-md'>Execution Date</p>
            </div>
          </TableColumn>
          {/*    NOTE: hidden until we add backend functionality to track credits per execution
          <TableColumn>
            <div className='flex flex-row items-center'>
              <iconify-icon
                class='mr-1'
                icon='ph:money-bold'
                width='14'
                height='14'
              />
              <p className='text-md hidden'>Credits Used</p>

            </div>
          </TableColumn>
          */}
          <TableColumn>
            <div className='flex flex-row items-center'>
              <iconify-icon
                class='mr-1'
                icon='material-symbols:timer'
                width='14'
                height='14'
              />
              <p className='text-md'>Duration</p>
            </div>
          </TableColumn>
          <TableColumn>
            <div className='flex flex-row items-center'>
              <iconify-icon
                class='mr-1'
                icon='material-symbols:info'
                width='14'
                height='14'
              />
              <p className='text-md'>Status</p>
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
        <TableBody
          items={items}
          loadingState={loadingState}
          emptyContent={
            <div className='text-center py-6 text-gray-500'>
              <p className='text-lg'>No Executions Found</p>
              <p className='text-sm'>This workflow hasn't been run yet.</p>
            </div>
          }
        >
          {(item) => (
            <TableRow key={item.id}>
              <TableCell>
                <div className='flex items-center gap-2'>
                  <p className='font-mono text-gray-500'>{item.id}</p>
                  <Tooltip content='Click to copy' closeDelay={0}>
                    <Button
                      isIconOnly
                      size='sm'
                      variant='light'
                      onPress={() => {
                        navigator.clipboard.writeText(item.id)
                        const button =
                          document.activeElement as HTMLButtonElement
                        const icon = button.querySelector('iconify-icon')
                        if (icon) {
                          icon.setAttribute('icon', 'material-symbols:check')
                          setTimeout(() => {
                            icon.setAttribute('icon', 'lucide:copy')
                          }, 2000)
                        }
                      }}
                    >
                      <iconify-icon icon='lucide:copy' width='14' height='14' />
                    </Button>
                  </Tooltip>
                </div>
              </TableCell>
              <TableCell>
                <div>
                  <p>
                    {intlFormatDistance(new Date(item.inserted_at), new Date())}{' '}
                  </p>
                  <span className='text-gray-400 font-mono'>
                    {new Date(item.inserted_at).toLocaleString('en-US', {
                      month: 'short',
                      day: 'numeric',
                      year: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit',
                      second: '2-digit',
                      hour12: false,
                    })}
                  </span>
                </div>
              </TableCell>
              {/* NOTE: hidden until we add backend functionality to track credits per execution
              <TableCell>
                <p className='text-right'>{DEFAULT_COST}</p>
              </TableCell>
              */}
              <TableCell>
                <p className='text-right font-mono'>
                  {item.updated_at
                    ? `${(
                        (new Date(item.updated_at).getTime() -
                          new Date(item.inserted_at).getTime()) /
                        1000
                      ).toFixed(2)} s`
                    : 'N/A'}
                </p>
              </TableCell>
              <TableCell>
                <Tooltip
                  content={
                    item.status === 'completed'
                      ? 'Completed successfully'
                      : item.status === 'started'
                      ? 'Workflow is executing'
                      : item.status === 'delayed'
                      ? 'Retrying a task'
                      : item.status === 'pending'
                      ? "Workflow hasn't started yet"
                      : 'Cancelled by user or at least one task errored too many times'
                  }
                >
                  <Chip
                    size='sm'
                    variant='flat'
                    color={
                      item.status === 'completed'
                        ? 'success'
                        : item.status === 'started'
                        ? 'warning'
                        : item.status === 'delayed'
                        ? 'warning'
                        : item.status === 'pending'
                        ? 'default'
                        : 'danger'
                    }
                  >
                    {item.status.charAt(0).toUpperCase() + item.status.slice(1)}
                  </Chip>
                </Tooltip>
              </TableCell>
              <TableCell>
                <div className='flex items-center gap-2'>
                  <Tooltip content='See data slots' closeDelay={0}>
                    <iconify-icon
                      class='cursor-pointer '
                      icon='mdi:database-eye'
                      width='22'
                      height='22'
                      onClick={() =>
                        onOpenInputOutputModal({
                          activeTab: 'input',
                          execution: item,
                        })
                      }
                    />
                  </Tooltip>
                  <Tooltip
                    content='Re-run workflow with same inputs'
                    closeDelay={0}
                  >
                    <iconify-icon
                      class='cursor-pointer text-green-500'
                      icon='ic:twotone-replay-circle-filled'
                      width='22'
                      height='22'
                      onClick={() => onRepeatExecutionButtonClick(item.id)}
                    />
                  </Tooltip>
                  {!['cancelled', 'completed'].includes(item.status) && (
                    <Tooltip content='Cancel execution' closeDelay={0}>
                      <iconify-icon
                        class='cursor-pointer text-red-500'
                        icon='ic:round-cancel'
                        width='22'
                        height='22'
                        onClick={() => handleCancelExecution(item.id)}
                      />
                    </Tooltip>
                  )}

                  {['cancelled', 'completed'].includes(item.status) && (
                    <Tooltip content='Cancel execution' closeDelay={0}>
                      <iconify-icon
                        class='cursor-not-allowed text-gray-400'
                        icon='ic:round-cancel'
                        width='22'
                        height='22'
                        onClick={() => handleCancelExecution(item.id)}
                      />
                    </Tooltip>
                  )}
                </div>
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  )
}

export default LastExecutionsTable
