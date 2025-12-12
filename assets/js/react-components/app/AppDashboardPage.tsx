import React, { useState } from 'react'
import { useDisclosure } from '@nextui-org/react'
import PageTitle from '../common/PageTitle'
import WorkflowStats from './WorkflowStats'
import DashboardShortcuts from './DashboardShortcuts'
import LastExecutionsTable from './LastExecutionsTable'
import ScheduledTriggersTable from './ScheduledTriggersTable'
import ExecutionModal from './modal/ExecutionModal'
import InputOutputModal from './modal/InputOutputModal'
import type {
  OnOpenExecutionModal,
  OnOpenInputOutputModal,
  TAppDashboardPageProps,
  TExecution,
  TScheduledTrigger,
} from 'types/app'

/**
 * Component that renders the App Dashboard page
 * @constructor
 */
const AppDashboardPage: React.FC<
  LiveReactComponentProps<TAppDashboardPageProps>
> = ({
  pushEvent,
  props: {
    workflow,
    shortcuts,
    executions,
    workflow_inputs_definition,
    scheduled_triggers,
    workflow_id,
    execution_time,
    total_executions,
    active_triggers,
  },
}) => {
  /**
   * These hooks handle the modals functionality.
   */
  const modalHooks = {
    execution: useDisclosure(),
    inputOutput: useDisclosure(),
  }

  const [trigger, setTrigger] = useState<TScheduledTrigger | null>()
  const [IOExecution, setIOExecution] = useState<TExecution>()
  const [ITrigger, setITrigger] = useState<TScheduledTrigger>()
  const [activeTab, setActiveTab] = useState<'input' | 'output'>('input')

  /**
   * Callback executed when the New Execution button or New Scheduled Trigger button has been clicked.
   * @param trigger (Optional) Scheduled Trigger to edit.
   */
  const onOpenExecutionModal: OnOpenExecutionModal = (trigger) => {
    setTrigger(trigger)
    modalHooks.execution.onOpen()
  }

  /**
   * Callback executed when the Input/Output button has been clicked.
   */
  const onOpenInputOutputModal: OnOpenInputOutputModal = ({
    trigger,
    execution,
    activeTab,
  }) => {
    setIOExecution(execution)
    setITrigger(trigger)
    setActiveTab(activeTab)
    modalHooks.inputOutput.onOpen()
  }

  return (
    <>
      <PageTitle
        title={`Workflow Dashboard: ${workflow.name}`}
        icon='ix:dashboard'
      />
      <DashboardShortcuts shortcuts={shortcuts} />
      <WorkflowStats
        executionTime={execution_time}
        totalExecutions={total_executions}
        activeTriggers={active_triggers}
      />
      <LastExecutionsTable
        workflow_id={workflow_id}
        pushEvent={pushEvent}
        executions={executions}
        totalExecutions={total_executions}
        onOpenExecutionModal={onOpenExecutionModal}
        onOpenInputOutputModal={onOpenInputOutputModal}
      />
      <ScheduledTriggersTable
        pushEvent={pushEvent}
        scheduledTriggers={scheduled_triggers}
        onOpenExecutionModal={onOpenExecutionModal}
        onOpenInputOutputModal={onOpenInputOutputModal}
      />
      <ExecutionModal
        workflowId={workflow_id}
        isOpen={modalHooks.execution.isOpen}
        onOpenChange={modalHooks.execution.onOpenChange}
        onClose={() => {
          setTrigger(undefined)
          modalHooks.execution.onClose()
        }}
        pushEvent={pushEvent}
        inputs={workflow_inputs_definition}
        trigger={trigger}
      />
      <InputOutputModal
        execution={IOExecution}
        trigger={ITrigger}
        activeTab={activeTab}
        isOpen={modalHooks.inputOutput.isOpen}
        onOpenChange={modalHooks.inputOutput.onOpenChange}
        onClose={() => {
          modalHooks.inputOutput.onClose()
        }}
      />
    </>
  )
}

export default AppDashboardPage
