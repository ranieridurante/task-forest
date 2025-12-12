import type { TInitialEdge } from '../workflow'
import type { EdgeChange } from 'reactflow'
import type { TExecution, TExecutionStatus, TScheduledTrigger } from 'types/app'

declare global {
  interface LiveViewEventDetail {
    'server.update_editor': {
      changes: {
        edge_changes?: ({
          item: TInitialEdge
        } & EdgeChange)[]
        node_changes?: any[]
      }
    }
    'server.execution_update': {
      execution: TExecution
      status: TExecutionStatus
    }
    'server.workflow_update': {
      execution_id: string
      status: TExecutionStatus
      outputs?: {
        [key: string]: unknown
      }
    }
    'server.executions_retrieved': {
      executions: TExecution[]
      page: number
      page_size: number
    }
  }

  type LiveViewEventCallback<K extends keyof LiveViewEventDetail> = (
    data: LiveViewEventDetail[K]
  ) => void

  interface ReactPushRequestTypes {
    /**
     * Deletes a Converger
     */
    'react.delete_converger': {
      /**
       * Converger Id
       */
      converger_id: string

      /**
       * Workflow Id
       */
      workflow_id: string
    }
    'react.create_iterator': {
      workflow_id: string
      iterable_key: string
    }
    'react.create_filter': {
      workflow_id: string
      filter: TFilter
    }
    'react.delete_iterator': {
      iterator_id: string
      workflow_id: string
    }
    'react.dashboard_repeat_execution': {
      execution_id: string
    }
    'react.update_scheduled_trigger': Partial<TScheduledTrigger>
    'react.delete_scheduled_trigger': {
      scheduled_trigger_id: string
    }
    'react.execute_workflow': {
      inputs: {
        [key: string]: unknown
      }
      workflow_id: string
    }
    'react.cancel_execution': {
      execution_id: string
    }
    'react.create_scheduled_trigger': Partial<TScheduledTrigger>
    'react.retrieve_executions': {
      workflow_id: string
      page_size: number
      page: number
    }
    'react.create_workflow': {
      company_id: string
      name: string
    }
    'react.delete_workflow': {
      workflow_id: string
    }
  }

  type PushEventFunction = <K extends keyof ReactPushRequestTypes | string>(
    eventType: K,
    data: ReactPushRequestTypes[K],
    onReply?: (reply: any, ref: any) => void
  ) => void

  type PushEventToFunction = (
    phxTarget: any,
    event: string,
    payload?: any,
    onReply?: (reply: any, ref: any) => void
  ) => any

  type HandleEventFunction = (
    event: string,
    callback: (payload: any) => void
  ) => any

  type LiveReactComponentProps<T> = {
    pushEvent: PushEventFunction
    pushEventTo: PushEventToFunction
    handleEvent: HandleEventFunction
    props: T
  }
}

export {}
