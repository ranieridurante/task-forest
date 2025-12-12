import type {
  InputChange,
  OutputChange,
  TTask,
  TTaskModalProps,
  TTaskPayload,
  TTaskProvider,
  TTaskTemplate,
  TTaskTemplatesCollection,
} from 'types/task'
import {
  BreadcrumbItem,
  Breadcrumbs,
  Button,
  Divider,
  Modal,
  ModalBody,
  ModalContent,
  ModalFooter,
  ModalHeader,
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@nextui-org/react'
import React, { useEffect, useRef, useState } from 'react'
import TaskProviderGrid from '../tasks/TaskProviderGrid'
import TaskTemplateGrid from '../tasks/TaskTemplateGrid'
import TaskForm from '../tasks/TaskForm'
import type { SwiperFunctions } from '../../common/Swiper'
import Swiper from '../../common/Swiper'

type TBreadcrumbStatus = {
  title: string
  icon: string
  visible?: boolean
}

/**
 * Default state of provider breadcrumb.
 */
const DEFAULT_PROVIDER_BREADCRUMB: TBreadcrumbStatus = {
  title: 'Select a provider',
  icon: 'ic:twotone-api',
}

/**
 * Default state of task breadcrumb.
 */
const DEFAULT_TASK_BREADCRUMB: TBreadcrumbStatus = {
  title: 'Select a task',
  icon: 'jam:task-list-f',
  visible: false,
}

/**
 * Enumerable representing the ids of the Swiper slides.
 */
enum TASK_MODAL_SLIDES {
  SELECT_PROVIDER = 0,
  SELECT_TASK_TEMPLATE = 1,
  TASK_FORM = 2,
}

/**
 * Enumerable that represents the React events that are sent to the server.
 */
enum REACT_EVENT {
  CREATE_TASK = 'react.create_task',
  UPDATE_TASK = 'react.update_task',
  DELETE_TASK = 'react.delete_task',
}

/**
 * Returns a Map of TaskProviders, filtering the entire list of TaskTemplatesCollection by the provider_slug value.
 *
 * Use the corresponding endpoint to receive the list of suppliers along with the featured suppliers list.
 * @param taskTemplates List of TaskTemplates
 */
const getTaskProviders = (taskTemplates?: TTaskTemplatesCollection) => {
  const taskProvidersMap = new Map<string, TTaskProvider>()

  if (taskTemplates) {
    Object.values(taskTemplates).map((template) => {
      if (!taskProvidersMap.has(template.provider_slug)) {
        taskProvidersMap.set(template.provider_slug, {
          name: template.provider_name,
          slug: template.provider_slug,
          style: template.style,
        })
      }
    })
  }

  return taskProvidersMap
}

/**
 * Represents a modal component for adding or editing a task within a workflow.
 * @constructor
 */
const TaskModal: React.FC<TTaskModalProps> = ({
  isOpen,
  onOpenChange,
  onClose,
  task,
  taskTemplates,
  workflow_id,
  pushEvent,
}) => {
  /**
   * Swiper reference
   */
  const swiperRef = useRef<SwiperFunctions>(null)

  const [modalAction, setModalAction] = useState<string>('Add new task')
  const [providers, setProviders] = useState<Map<string, TTaskProvider>>(
    new Map<string, TTaskProvider>()
  )
  const [taskTemplatesForProvider, setTaskTemplatesForProvider] = useState<
    TTaskTemplate[]
  >([])
  const [actualTask, setActualTask] = useState<TTask | undefined>()
  const [providerBreadcrumb, setProviderBreadcrumb] =
    useState<TBreadcrumbStatus>(DEFAULT_PROVIDER_BREADCRUMB)
  const [taskBreadcrumb, setTaskBreadcrumb] = useState<TBreadcrumbStatus>(
    DEFAULT_TASK_BREADCRUMB
  )

  // If task isn't provided, show breadcrumbs
  // Main swiper at step 1 if task isn't provided, swiper at step 3 if task is provided
  useEffect(() => {
    if (isOpen) {
      // Edit mode
      if (task && task.task_id) {
        setModalAction('Edit task')
        // https://developer.mozilla.org/en-US/docs/Web/API/structuredClone
        // https://caniuse.com/?search=structuredClone 92.51%
        setActualTask(structuredClone(task))
        if (swiperRef.current) {
          swiperRef.current.goToSlide(TASK_MODAL_SLIDES.TASK_FORM)
        }
      } else {
        // Create mode
        setModalAction('Add new task')
        const taskProvidersMap = getTaskProviders(taskTemplates)
        setProviders(taskProvidersMap)
      }
    }
  }, [isOpen])

  /**
   * Function that is executed when a provider is selected in the TaskProviderGrid screen.
   * @param taskProviderSlug Selected Task Provider Slug
   */
  const onTaskProviderSelect = (taskProviderSlug: string) => {
    if (swiperRef.current) {
      swiperRef.current.goToSlide(TASK_MODAL_SLIDES.SELECT_TASK_TEMPLATE)
    }

    const provider = providers.get(taskProviderSlug)
    if (provider) {
      setProviderBreadcrumb({
        title: provider.name,
        icon: provider.style.icon,
      })
      setTaskBreadcrumb({
        ...taskBreadcrumb,
        visible: true,
      })

      // TODO Get and set all task templates for provider from endpoint
      setTaskTemplatesForProvider(
        Object.values(taskTemplates).filter(
          (taskTemplate) => taskTemplate.provider_slug === taskProviderSlug
        )
      )
    }
  }

  /**
   * Function that is executed when a TaskTemplate is selected in the TaskTemplateGrid screen.
   * @param taskTemplate Selected Task Template
   */
  const onTaskTemplateSelect = (taskTemplate: TTaskTemplate) => {
    if (swiperRef.current) {
      swiperRef.current.goToSlide(TASK_MODAL_SLIDES.TASK_FORM)
    }

    setActualTask({
      task_config: taskTemplate.config,
      inputs_definition: taskTemplate.inputs_definition,
      outputs_definition: taskTemplate.outputs_definition,
      task_template: taskTemplate,
      task_template_id: taskTemplate.id,
    })
  }

  /**
   * Function that is executed when clicking on the TaskProvider breadcrumb.
   */
  const onProviderBreadcrumbClick = () => {
    if (swiperRef.current) {
      const currentSlide = swiperRef.current.getCurrentSlide()
      const isEditingTask = !task?.task_id

      if (currentSlide === TASK_MODAL_SLIDES.SELECT_TASK_TEMPLATE) {
        swiperRef.current.goToSlide(TASK_MODAL_SLIDES.SELECT_PROVIDER)
        setProviderBreadcrumb({ ...DEFAULT_PROVIDER_BREADCRUMB })
        setTaskBreadcrumb({ ...DEFAULT_TASK_BREADCRUMB })
        setActualTask(undefined)
        setTaskTemplatesForProvider([])
      } else if (
        currentSlide === TASK_MODAL_SLIDES.TASK_FORM &&
        isEditingTask
      ) {
        swiperRef.current.goToSlide(TASK_MODAL_SLIDES.SELECT_TASK_TEMPLATE)
        setActualTask(undefined)
        setTaskBreadcrumb({ ...DEFAULT_TASK_BREADCRUMB, visible: true })
      }
    }
  }

  /**
   * Function responsible for updating the input data.
   * @param key Key of the input attribute.
   * @param newValue Value of the input attribute.
   */
  const handleInputChange: InputChange = (key, newValue) => {
    if (actualTask) {
      if (actualTask.inputs_definition[key]) {
        actualTask.inputs_definition[key] =
          actualTask.task_template.inputs_definition[key]

        actualTask.inputs_definition[key] = {
          ...actualTask.inputs_definition[key],
          value: newValue,
        }

        setActualTask(structuredClone(actualTask))
      }
    }
  }

  /**
   * Function responsible for updating output information. Mainly for tasks with language models.
   * @param key Key of the output attribute.
   * @param type Data type of the output attribute.
   */
  const handleOutputChange: OutputChange = (key, type) => {
    if (actualTask) {
      if (type) {
        actualTask.outputs_definition[key] = {
          type,
        }
      } else {
        delete actualTask.outputs_definition[key]
      }
      setActualTask(structuredClone(actualTask))
    }
  }

  const handleModelChange: InputChange = (key, newValue) => {
    if (actualTask && actualTask.task_config.type === 'model') {
      if (key === 'prompt') {
        actualTask.task_config.model_params.prompt = newValue.toString()
      } else if (key === 'model_id') {
        actualTask.task_config.model_id = newValue.toString()
      }

      setActualTask(structuredClone(actualTask))
    }
  }

  /**
   * Function that creates or updates a task within a workflow.
   */
  const onSave = () => {
    if (actualTask) {
      const payload: TTaskPayload = {
        task_type: actualTask.task_template.config.type,
        task_template_id: actualTask.task_template_id,
        workflow_id: workflow_id || task?.workflow_id,
        task_id: actualTask.task_id,
        name: actualTask.label || actualTask.task_template.name,
        params: {
          inputs_definition: actualTask.inputs_definition,
        },
      }

      if (actualTask.task_config.type === 'model') {
        payload.params = {
          config_overrides: {
            model_id: actualTask.task_config.model_id,
            model_params: {
              prompt: actualTask.task_config.model_params.prompt || '',
            },
          },
          inputs_definition: actualTask.inputs_definition,
          outputs_definition: actualTask.outputs_definition,
        }
      }

      if (actualTask.task_id) {
        pushEvent(REACT_EVENT.UPDATE_TASK, payload)
      } else {
        pushEvent(REACT_EVENT.CREATE_TASK, payload)
      }

      if (onClose) {
        onClose()
        resetModalStatus()
      }
    }
  }

  /**
   * Function that deletes a task within a workflow.
   */
  const onDelete = () => {
    pushEvent(REACT_EVENT.DELETE_TASK, {
      task_id: actualTask?.task_id,
      workflow_id: workflow_id,
    })

    if (onClose) {
      onClose()
      resetModalStatus()
    }
  }

  /**
   * Function that resets the state of the modal.
   */
  const resetModalStatus = () => {
    if (isOpen) {
      setProviderBreadcrumb(DEFAULT_PROVIDER_BREADCRUMB)
      setTaskBreadcrumb(DEFAULT_TASK_BREADCRUMB)
      setTaskTemplatesForProvider([])
      setActualTask(undefined)
      if (onOpenChange) {
        onOpenChange(isOpen)
      }
    }
  }

  // TODO: Make use of this
  /* const searchProvidersByName = (term: string) => {
    pushEvent('react.search_providers', {
      term: term,
    })
  }

  const getProviderTaskTemplates = (provider_slug: string) => {
    pushEvent('react.get_provider_task_templates', {
      provider_slug: provider_slug,
    })
  }

  useEffect(() => {
    const updateTaskFormButtonProviders = (e: Event) => {
      const server_event_data: TServerEvent = e.detail
      /!*
      server_event_data = {
        "providers": <TProvider[]>
      }
      *!/
    }

    window.addEventListener(
      'phx:server.update_provider_search_results',
      updateTaskFormButtonProviders,
    )

    return () => {
      window.removeEventListener(
        'phx:server.update_provider_search_results',
        updateTaskFormButtonProviders,
      )
    }
  }, []) */

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      onOpenChange={resetModalStatus}
      size='3xl'
      scrollBehavior='inside'
      placement='top-center'
      backdrop='blur'
      className='bg-plombYellow-500'
    >
      <ModalContent>
        <ModalHeader className='flex-col gap-2'>
          <div className='flex flex-row items-center w-full'>
            <iconify-icon
              icon='hugeicons:task-edit-02'
              width='32'
              height='32'
            />
            <h1 className='text-plombBlack-500 text-2xl ml-4'>
              {modalAction}
              {actualTask
                ? `: ${actualTask.label || actualTask.task_template.name}`
                : ''}
            </h1>
          </div>
          <Divider orientation='horizontal' />
          <Breadcrumbs variant='solid'>
            <BreadcrumbItem
              startContent={
                <iconify-icon
                  icon='hugeicons:task-edit-02'
                  width='24'
                  height='24'
                />
              }
            >
              {modalAction}
            </BreadcrumbItem>
            <BreadcrumbItem
              onPress={onProviderBreadcrumbClick}
              startContent={
                <iconify-icon
                  icon={
                    actualTask
                      ? actualTask.task_template.style.icon
                      : providerBreadcrumb.icon
                  }
                  width='24'
                  height='24'
                />
              }
            >
              {actualTask
                ? actualTask.task_template.provider_name
                : providerBreadcrumb.title}
            </BreadcrumbItem>
            {(taskBreadcrumb.visible || actualTask?.task_template) && (
              <BreadcrumbItem
                startContent={
                  <iconify-icon
                    icon={taskBreadcrumb.icon}
                    width='24'
                    height='24'
                  />
                }
              >
                {actualTask
                  ? actualTask.task_template.name
                  : taskBreadcrumb.title}
              </BreadcrumbItem>
            )}
          </Breadcrumbs>
        </ModalHeader>
        <ModalBody>
          <Swiper ref={swiperRef}>
            <TaskProviderGrid
              taskProviders={providers}
              onTaskProviderSelect={onTaskProviderSelect}
            />
            <TaskTemplateGrid
              taskTemplates={taskTemplatesForProvider}
              onTaskTemplateSelect={onTaskTemplateSelect}
            />
            <TaskForm
              task={actualTask}
              setActualTask={setActualTask}
              handleInputChange={handleInputChange}
              handleOutputChange={handleOutputChange}
              handleModelChange={handleModelChange}
            />
          </Swiper>
        </ModalBody>
        <ModalFooter>
          {task?.task_id && (
            <Popover placement='top-start'>
              <PopoverTrigger>
                <Button
                  style={{
                    marginRight: 'auto',
                  }}
                  isIconOnly
                  color='danger'
                  aria-label='Like'
                >
                  <iconify-icon icon='tabler:trash' width='24' height='24' />
                </Button>
              </PopoverTrigger>
              <PopoverContent>
                {(titleProps) => (
                  <div className='flex flex-col px-1 py-2'>
                    <h3 className='text-small font-bold' {...titleProps}>
                      Deleting Task
                    </h3>
                    <div className='text-tiny my-1'>
                      <p>
                        Are you sure you want to delete the task
                        <b> {actualTask?.label}?</b>
                      </p>
                      <p className='italic'>This action cannot be undone.</p>
                    </div>
                    <Button
                      style={{
                        alignSelf: 'end',
                      }}
                      color='danger'
                      aria-label='Like'
                      onPress={onDelete}
                    >
                      <iconify-icon
                        icon='tabler:trash'
                        width='24'
                        height='24'
                      />
                      Delete task
                    </Button>
                  </div>
                )}
              </PopoverContent>
            </Popover>
          )}
          <Button
            className='shrink-0'
            color='primary'
            onPress={() => {
              resetModalStatus()
            }}
          >
            Close
          </Button>
          <Button
            isDisabled={actualTask === undefined}
            className='shrink-0'
            color='primary'
            onPress={onSave}
          >
            Save
          </Button>
        </ModalFooter>
      </ModalContent>
    </Modal>
  )
}

export default TaskModal
