import React, { useState, useEffect } from 'react'
import { Button, Input, Tabs, Tab } from '@nextui-org/react'
import clsx from 'clsx'
import PageTitle from '../common/PageTitle'
import type { InputChange, TIODefinitions } from 'types/task'
import InputsForm from '../common/InputsForm'
import {
  addLiveViewEventListener,
  removeLiveViewEventListener,
} from '../../util'
import type { TRunWorkflowButtonProps } from 'types/app'
import '@andypf/json-viewer'
import type { LogEntry } from './LogConsole'
import LogConsole from './LogConsole'

type WorkflowInput = {
  id: number
  value: string
}

const WorkflowPlayground: React.FC<TWorkflowPlaygroundProps> = ({
  props: { workflow: workflow },
  pushEvent,
}) => {
  const PLOMB_JSON_VIEWER_THEME =
    '{"base00": "#4B2E2E", "base01": "#4B2E2E", "base02": "#4B2E2E", "base03": "#4B2E2E", "base04": "#4B2E2E", "base05": "#e5bdbd", "base06": "#e5bdbd", "base07": "#e5bdbd", "base08": "#8C4C47", "base09": "#ffc57d", "base0A": "#CD5D57", "base0B": "#E56B66", "base0C": "#E56B66", "base0D": "#ff7b75", "base0E": "#ff7b75", "base0F": "#ff7b75"}'

  const DEFAULT_EXECUTION_OUTPUT = JSON.stringify({
    message: "Click 'Test Workflow' to see the results.",
  })

  const RUN_WORKFLOW_BUTTON_PROPS: TRunWorkflowButtonProps = {
    text: 'Test Workflow',
    icon: 'grommet-icons:test',
    color: 'primary',
    class: 'bg-plombPink-500',
    isRunning: false,
  }
  const CANCEL_WORKFLOW_EXECUTION_BUTTON_PROPS: TRunWorkflowButtonProps = {
    text: 'Cancel Execution',
    icon: 'mdi:cancel-bold',
    color: 'danger',
    class: '',
    isRunning: true,
  }

  const placeholders = structuredClone(workflow?.inputs_definition || {})

  const emptyInputs = structuredClone(workflow?.inputs_definition || {})
  Object.keys(emptyInputs).map((key) => {
    emptyInputs[key].value = undefined
  })

  const [executionInputs, setExecutionInputs] =
    useState<TIODefinitions>(emptyInputs)
  const [executionId, setExecutionId] = useState<string>()
  const [executionOutput, setExecutionOutput] = useState<string>(
    DEFAULT_EXECUTION_OUTPUT
  )
  const [runWorkflowButtonProps, setRunWorkflowButtonProps] =
    useState<TRunWorkflowButtonProps>(RUN_WORKFLOW_BUTTON_PROPS)

  const [logs, setLogs] = useState<LogEntry[]>([
    {
      timestamp: new Date().toLocaleTimeString(),
      message: 'Here you will see logs as your workflow executes.',
      level: 'info',
    },
    {
      timestamp: new Date().toLocaleTimeString(),
      message: 'Warnings will show like this.',
      level: 'warn',
    },
    {
      timestamp: new Date().toLocaleTimeString(),
      message: "And here's an error too.",
      level: 'error',
    },
  ])

  const getInputs = () =>
    Object.entries(executionInputs).reduce((acc, [key, { value }]) => {
      return { ...acc, [key]: value || placeholders[key].value || null }
    }, {})

  const onRunWorkflowButtonClick = () => {
    if (runWorkflowButtonProps.isRunning) {
      if (executionId) {
        pushEvent('react.cancel_execution', {
          execution_id: executionId,
        })
      }
      setRunWorkflowButtonProps(RUN_WORKFLOW_BUTTON_PROPS)
    } else {
      const inputs = getInputs()
      setExecutionOutput(
        JSON.stringify({
          message: 'Execution in progress.',
        })
      )
      pushEvent('react.execute_workflow', {
        inputs,
        workflow_id: workflow?.id,
      })
      setRunWorkflowButtonProps(CANCEL_WORKFLOW_EXECUTION_BUTTON_PROPS)
      // TODO Select Outputs tab

      setLogs([
        {
          timestamp: new Date().toLocaleTimeString(),
          message: 'Executing workflow...',
          level: 'info',
        },
      ])
    }
  }

  const handleInputChange: InputChange = (key, newValue) => {
    if (executionInputs[key]) {
      executionInputs[key].value = newValue
      setExecutionInputs(structuredClone(executionInputs))
    }
  }

  const resetPlayground = () => {
    setExecutionInputs(emptyInputs)
    setExecutionOutput(DEFAULT_EXECUTION_OUTPUT)
  }

  const [selectedTab, setSelectedTab] = useState<'output' | 'input'>('output')

  useEffect(() => {
    /**
     * Callback executed when the server sends an execution update.
     */
    const onWorkflowUpdate: LiveViewEventCallback<'server.workflow_update'> = ({
      execution_id,
      status,
      outputs,
    }) => {
      setExecutionId(execution_id)
      if (outputs) {
        setExecutionOutput(
          JSON.stringify({
            execution_id,
            status,
            outputs,
          })
        )

        // Add log entry
        setLogs((prev) => [
          ...prev,
          {
            timestamp: new Date().toLocaleTimeString(),
            message: `${status}: ${JSON.stringify(outputs)}`,
            level: status === 'error' ? 'error' : 'info',
          },
        ])
      }
    }

    addLiveViewEventListener('server.workflow_update', onWorkflowUpdate)
    return removeLiveViewEventListener(
      'server.workflow_update',
      onWorkflowUpdate
    )
  }, [])

  return (
    <div className='w-full min-h-screen p-8 flex flex-col gap-6 text-[#4B2E2E]'>
      <PageTitle
        title={`Workflow Playground: ${workflow?.name}`}
        icon='grommet-icons:test'
      />

      <div className='flex flex-col lg:flex-row gap-8 w-full'>
        <div className='w-full lg:w-1/2 space-y-6'>
          <div className='flex flex-row items-center mb-4'>
            <iconify-icon icon='mdi:input' width='22' height='22' />
            <h2 className='text-xl grow ml-2'>Workflow Inputs</h2>
          </div>
          <InputsForm
            placeholders={placeholders}
            inputs_definition={workflow?.inputs_definition || {}}
            handleInputChange={handleInputChange}
          />
          <div className='flex flex-row justify-end'>
            <Button
              color={runWorkflowButtonProps.color}
              className={runWorkflowButtonProps.class}
              onPress={() => onRunWorkflowButtonClick()}
              startContent={
                <iconify-icon
                  icon={runWorkflowButtonProps.icon}
                  width='16'
                  height='16'
                />
              }
            >
              {runWorkflowButtonProps.text}
            </Button>
          </div>
        </div>

        <div className='w-full lg:w-1/2 space-y-4'>
          <div className='flex flex-row items-center mb-4'>
            <iconify-icon icon='mdi:output' width='22' height='22' />
            <h2 className='text-xl grow ml-2'>Execution Results</h2>
          </div>
          <Tabs
            selectedKey={selectedTab}
            onSelectionChange={(key) =>
              setSelectedTab(key as 'output' | 'input')
            }
            variant='underlined'
            classNames={{
              tabList: 'gap-6',
              tab: 'text-[#4B2E2E] font-medium',
              cursor: 'bg-[#D31C77]',
            }}
          >
            <Tab key='output' title='Outputs' />
            <Tab key='input' title='Inputs' />
          </Tabs>

          <div className='overflow-y-auto max-h-[50vh]'>
            <andypf-json-viewer
              class='text-lg !font-mono'
              expanded={3}
              indent={4}
              show-copy={true}
              show-data-types={false}
              show-toolbar={true}
              expand-icon-type='arrow'
              show-size={false}
              theme={PLOMB_JSON_VIEWER_THEME}
              data={
                selectedTab === 'output'
                  ? executionOutput
                  : JSON.stringify(getInputs())
              }
            />
          </div>
        </div>
      </div>

      {/* Bottom Section with Debug Console and Run Button */}
      <div className='flex flex-col gap-2 mt-4'>
        {/* Debug Console Header and Run Button */}
        <div className='flex items-center justify-between text-[#4B2E2E]'>
          <div className='flex flex-row items-center mb-4'>
            <iconify-icon icon='mdi:bug-outline' width='22' height='22' />
            <h2 className='text-xl grow ml-2'>Debug Logs</h2>
          </div>
        </div>

        <LogConsole logs={logs} />
      </div>
    </div>
  )
}

export default WorkflowPlayground
