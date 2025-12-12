import React, { useState, useEffect } from 'react'
import {
  Button,
  Link,
  Table,
  TableHeader,
  TableColumn,
  TableBody,
  TableRow,
  TableCell,
  Tooltip,
  getKeyValue,
  useDisclosure,
} from '@nextui-org/react'
import clsx from 'clsx'
import PageTitle from '../common/PageTitle'
import DashboardShortcuts from '../app/DashboardShortcuts'
import type TWorkflowHeaderProps from '../types/app'
import type TWorkflowCardItem from '../types/workflow'
import { intlFormatDistance } from 'date-fns'
import DeleteWorkflowModal from './DeleteWorkflowModal'
import CreateWorkflowTemplateModal from './CreateWorkflowTemplateModal'
import PreviewWorkflowModal from './PreviewWorkflowModal'
import { useDisclosure } from '@nextui-org/react'
import {
  addLiveViewEventListener,
  removeLiveViewEventListener,
} from '../../util'

type Workflow = {
  id: string
  name: string
  updated_at: string
  status: string
}

type WorkflowsPageProps = {
  workflows: Workflow[]
  active_company: {
    id: string
  }
}

const columns = [
  { key: 'name', label: 'Name', icon: 'mingcute:grid-fill' },
  {
    key: 'complexity',
    label: 'Complexity',
    icon: 'carbon:skill-level-advanced',
  },
  {
    key: 'inserted_at',
    label: 'Created',
    icon: 'material-symbols:calendar-month',
  },
  //  {
  //    key: 'last_execution_date',
  //    label: 'Last Run',
  //   icon: 'material-symbols:timer',
  //  },
  {
    key: 'template_slug',
    label: 'Template',
    icon: 'fa-solid:store',
  },
  { key: 'actions', label: 'Actions', icon: 'material-symbols:settings' },
]

const WorkflowHeader: React.FC<TWorkflowHeaderProps> = ({
  props: { onSearch, active_company, pushEvent },
}) => {
  const [searchTerm, setSearchTerm] = useState('')

  const handleSearch = (event: React.ChangeEvent<HTMLInputElement>) => {
    const query = event.target.value
    setSearchTerm(query)
    onSearch(query)
  }

  const handleKeyDown = (event: React.KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Enter') {
      onSearch(searchTerm)
    }
  }

  const handleNewWorkflow = () => {
    pushEvent('react.create_workflow', {
      company_id: active_company.id,
      name: 'Untitled Workflow',
    })
  }

  return (
    <div className='flex justify-between items-center text-[#4B2E2E] mb-6'>
      <div className='flex items-center border border-[#4B2E2E] rounded px-2 py-1 w-2/3 bg-white'>
        <iconify-icon
          icon='mdi:magnify'
          className='text-[#4B2E2E] mr-2'
          width='20'
          height='20'
        />
        <input
          type='text'
          placeholder='Search...'
          value={searchTerm}
          onChange={handleSearch}
          onKeyDown={handleKeyDown}
          className='w-full bg-transparent outline-none text-[#4B2E2E]'
        />
      </div>
      {/* Notification bell - will be shown once notifications are implemented
      <iconify-icon
        icon='mdi:bell-outline'
        className='text-[#4B2E2E]'
        width='24'
        height='24'
      /> */}
      <div className='flex gap-2 items-center'>
        <Button
          color='primary'
          className='bg-plombPink-500'
          onClick={handleNewWorkflow}
          startContent={
            <iconify-icon
              icon='streamline-ultimate:workflow-exit-door-bold'
              width='16'
              height='16'
            />
          }
        >
          New Workflow
        </Button>
      </div>
    </div>
  )
}

const WorkflowsPage: React.FC<LiveReactComponentProps<WorkflowsPageProps>> = ({
  props: {
    workflows,
    active_company,
    shortcuts,
    tasks_with_providers,
    provider_styles,
  },
  pushEvent,
}) => {
  const [workflowToDelete, setWorkflowToDelete] = useState<TWorkflowCardItem>()

  const [referenceWorkflow, setReferenceWorkflow] =
    useState<TWorkflowCardItem>()

  const [previewWorkflow, setPreviewWorkflow] = useState<TWorkflowCardItem>()

  const modalHooks = {
    deleteWorkflow: useDisclosure(),
    createWorkflowTemplate: useDisclosure(),
    previewWorkflow: useDisclosure(),
  }

  const taskWithProviderStyles = Object.entries(tasks_with_providers).reduce(
    (tasks: { [key: string]: TProviderStyle }, [taskId, style]) => {
      tasks[taskId] = provider_styles[style]
      return tasks
    },
    {}
  )

  const handleDuplicateWorkflow = (workflow_id: string) => {
    pushEvent('react.duplicate_workflow', {
      workflow_id: workflow_id,
    })
  }

  const onOpenDeleteWorkflowModal: OnDeleteWorkflowModal = (workflow) => {
    setWorkflowToDelete(workflow)
    modalHooks.deleteWorkflow.onOpen()
  }

  const onOpenPreviewWorkflowModal: OnPreviewWorkflowModal = (workflow) => {
    setPreviewWorkflow(workflow)
    modalHooks.previewWorkflow.onOpen()
  }

  const [filteredWorkflows, setFilteredWorkflows] =
    useState<Workflow[]>(workflows)

  const handleSearch = (query: string) => {
    const filtered = workflows.filter((workflow) =>
      workflow.name.toLowerCase().includes(query.toLowerCase())
    )
    setFilteredWorkflows(filtered)
  }

  const getStatusDot = (status: string) =>
    clsx(
      'h-3 w-3 rounded-full mr-2',
      status === 'Active' ? 'bg-green-500' : 'bg-gray-400'
    )

  const handleViewDetails = (workflow: Workflow) => {
    window.location.href = `/workflows/${workflow.id}/app-dashboard`
  }

  useEffect(() => {
    const onWorkflowDeleted: LiveViewEventCallback<
      'server.workflow_deleted'
    > = (data) => {
      const updatedWorkflows = filteredWorkflows.filter(
        (w) => w.id !== data.workflow_id
      )
      setFilteredWorkflows(updatedWorkflows)
    }

    addLiveViewEventListener('server.workflow_deleted', onWorkflowDeleted)
    return () =>
      removeLiveViewEventListener('server.workflow_deleted', onWorkflowDeleted)
  }, [filteredWorkflows])

  return (
    <div className='w-full text-[#4B2E2E] min-h-screen p-4'>
      <PageTitle title='Home' icon='material-symbols:home-outline' />
      <DashboardShortcuts shortcuts={shortcuts} />
      <div>
        <div className='flex justify-between items-center'>
          <div className='flex flex-row items-center mb-4'>
            <iconify-icon
              icon='fluent:settings-cog-multiple-24-regular'
              width='22'
              height='22'
            />
            <h2 className='text-xl grow ml-2'>Workflows</h2>
          </div>
        </div>

        <WorkflowHeader
          props={{
            onSearch: handleSearch,
            active_company: active_company,
            pushEvent: pushEvent,
          }}
        />

        <div className='overflow-x-auto rounded-md border border-gray-200 bg-white shadow'>
          <Table
            aria-label='Workflows table'
            isStriped
            classNames={{
              th: 'bg-gray-100 text-[#4B2E2E] font-medium text-left px-4 py-3 text-base',
              td: 'text-[#4B2E2E] px-4 py-3 text-base',
              base: 'text-[#4B2E2E]',
            }}
          >
            <TableHeader columns={columns}>
              {(column) => (
                <TableColumn key={column.key}>
                  <div className='flex flex-row items-center'>
                    <iconify-icon
                      class='mr-1'
                      icon={column.icon}
                      width='14'
                      height='14'
                    />
                    <p className='text-md'>{column.label}</p>
                  </div>
                </TableColumn>
              )}
            </TableHeader>
            <TableBody
              items={filteredWorkflows}
              emptyContent={
                <div className='flex flex-col items-center justify-center gap-4 py-8 text-gray-500'>
                  <iconify-icon
                    icon='fluent:apps-list-20-regular'
                    className='text-gray-500'
                    width='48'
                    height='48'
                  />
                  <div className='text-center'>
                    <p className='text-lg font-medium mb-2'>
                      No workflows to display
                    </p>
                    <p className='text-sm'>
                      No workflows match your search criteria
                    </p>
                  </div>
                </div>
              }
            >
              {(item) => (
                <TableRow key={item.id}>
                  {(columnKey) => {
                    if (columnKey === 'name') {
                      return (
                        <TableCell>
                          <Link
                            className={`${
                              item.name == 'Untitled Workflow'
                                ? 'text-gray-400'
                                : 'text-gray-700'
                            }`}
                            isBlock
                            isExternal
                            showAnchorIcon
                            href={`/workflows/${item.id}`}
                            title='Click to open workflow in Canvas'
                          >
                            {item.name}
                          </Link>
                        </TableCell>
                      )
                    }

                    if (columnKey === 'complexity') {
                      return (
                        <TableCell>
                          {item.complexity === 0 && (
                            <div
                              className='flex items-center justify-center'
                              title='This workflow is empty'
                            >
                              <iconify-icon
                                icon='carbon:skill-level'
                                width='24'
                                height='24'
                              />
                            </div>
                          )}
                          {item.complexity === 1 && (
                            <div
                              className='flex items-center justify-center'
                              title='This workflow is simple'
                            >
                              <iconify-icon
                                icon='carbon:skill-level-basic'
                                width='24'
                                height='24'
                              />
                            </div>
                          )}
                          {item.complexity === 2 && (
                            <div
                              className='flex items-center justify-center'
                              title='This workflow is somewhat complex'
                            >
                              <iconify-icon
                                icon='carbon:skill-level-intermediate'
                                width='24'
                                height='24'
                              />
                            </div>
                          )}
                          {item.complexity === 3 && (
                            <div
                              className='flex items-center justify-center'
                              title='This workflow is complex'
                            >
                              <iconify-icon
                                icon='carbon:skill-level-advanced'
                                width='24'
                                height='24'
                              />
                            </div>
                          )}
                        </TableCell>
                      )
                    }

                    if (columnKey === 'template_slug') {
                      return (
                        <TableCell>
                          {item.workflow_template &&
                            item.workflow_template.published && (
                              <Link
                                className='text-gray-700'
                                isBlock
                                isExternal
                                showAnchorIcon
                                color='success'
                                href={`/market/workflow-templates/${item.workflow_template.slug}`}
                                title='Click to see published template'
                              >
                                Live
                              </Link>
                            )}
                        </TableCell>
                      )
                    }
                    if (columnKey === 'actions') {
                      return (
                        <TableCell>
                          <div className='flex items-center gap-2'>
                            <Tooltip content='Preview workflow' closeDelay={0}>
                              <iconify-icon
                                class='cursor-pointer '
                                icon='tabler:eye-filled'
                                width='22'
                                height='22'
                                onClick={() => onOpenPreviewWorkflowModal(item)}
                              />
                            </Tooltip>
                            <Tooltip
                              content='See workflow dashboard'
                              closeDelay={0}
                            >
                              <iconify-icon
                                class='cursor-pointer text-plombDarkBrown-500'
                                icon='mdi:graph-line'
                                width='22'
                                height='22'
                                onClick={() =>
                                  (window.location.href = `/workflows/${item.id}/app-dashboard`)
                                }
                              />
                            </Tooltip>
                            <Tooltip
                              content='Test in Playground'
                              closeDelay={0}
                            >
                              <iconify-icon
                                class='cursor-pointer text-plombDarkBrown-500'
                                icon='grommet-icons:test'
                                width='22'
                                height='22'
                                onClick={() =>
                                  window.open(
                                    `/workflows/${item.id}/playground`,
                                    '_blank'
                                  )
                                }
                              />
                            </Tooltip>
                            <Tooltip
                              content='Edit workflow in Canvas'
                              closeDelay={0}
                            >
                              <iconify-icon
                                class='cursor-pointer text-plombDarkBrown-500'
                                icon='clarity:edit-solid'
                                width='22'
                                height='22'
                                onClick={() =>
                                  (window.location.href = `/workflows/${item.id}`)
                                }
                              />
                            </Tooltip>
                            <Tooltip
                              content='Duplicate workflow'
                              closeDelay={0}
                            >
                              <iconify-icon
                                class='cursor-pointer '
                                icon='famicons:duplicate'
                                width='22'
                                height='22'
                                onClick={() => handleDuplicateWorkflow(item.id)}
                              />
                            </Tooltip>
                            <Tooltip content='Delete workflow' closeDelay={0}>
                              <iconify-icon
                                class='cursor-pointer text-red-500'
                                icon='fluent:delete-16-filled'
                                width='22'
                                height='22'
                                onClick={() => onOpenDeleteWorkflowModal(item)}
                              />
                            </Tooltip>
                          </div>
                        </TableCell>
                      )
                    }
                    if (columnKey === 'inserted_at') {
                      return (
                        <TableCell>
                          <div>
                            <p>
                              {intlFormatDistance(
                                new Date(item.inserted_at),
                                new Date()
                              )}{' '}
                            </p>
                            <span className='text-gray-400 font-mono'>
                              {new Date(item.inserted_at).toLocaleString(
                                'en-US',
                                {
                                  month: 'short',
                                  day: 'numeric',
                                  year: 'numeric',
                                  hour: '2-digit',
                                  minute: '2-digit',
                                  second: '2-digit',
                                  hour12: false,
                                }
                              )}
                            </span>
                          </div>
                        </TableCell>
                      )
                    }
                    return <TableCell>{getKeyValue(item, columnKey)}</TableCell>
                  }}
                </TableRow>
              )}
            </TableBody>
          </Table>
        </div>
      </div>
      {workflowToDelete && (
        <DeleteWorkflowModal
          workflow={workflowToDelete}
          taskWithProviderStyles={taskWithProviderStyles}
          pushEvent={pushEvent}
          isOpen={modalHooks.deleteWorkflow.isOpen}
          onOpenChange={modalHooks.deleteWorkflow.onOpenChange}
          onClose={() => {
            modalHooks.deleteWorkflow.onClose()
          }}
        />
      )}
      {previewWorkflow && (
        <PreviewWorkflowModal
          workflow={previewWorkflow}
          taskWithProviderStyles={taskWithProviderStyles}
          pushEvent={pushEvent}
          isOpen={modalHooks.previewWorkflow.isOpen}
          onOpenChange={modalHooks.previewWorkflow.onOpenChange}
          onClose={() => {
            modalHooks.previewWorkflow.onClose()
          }}
          onEdit={() => {
            window.location.href = `/workflows/${previewWorkflow.id}`
          }}
          onDuplicate={() => handleDuplicateWorkflow(previewWorkflow.id)}
        />
      )}
      {referenceWorkflow && (
        <CreateWorkflowTemplateModal
          workflow={referenceWorkflow}
          pushEvent={pushEvent}
          isOpen={modalHooks.createWorkflowTemplate.isOpen}
          onOpenChange={modalHooks.createWorkflowTemplate.onOpenChange}
          onClose={() => {
            modalHooks.createWorkflowTemplate.onClose()
          }}
        />
      )}
    </div>
  )
}

export default WorkflowsPage
