import NavigationBreadcrumbs from '../layout/NavigationBreadcrumbs'
import React from 'react'
import type { TWorkflowEditorProps } from '../../types/workflow'
import WorkflowEditor from './WorkflowEditor'
import WorkflowTitle from './WorkflowTitle'
import { ReactFlowProvider } from 'reactflow'

const WorkflowEditorPage: React.FC<
  LiveReactComponentProps<TWorkflowEditorProps>
> = ({ props, pushEvent }) => {
  return (
    <div className='ml-4 mr-4 mb-4 sm:h-[98vh] h-[calc(100dvh_-_5.75rem)] flex flex-col relative'>
      <ReactFlowProvider>
        <div className='absolute z-[20] w-full'>
          {props.routes && props.routes.length > 0 && (
            <NavigationBreadcrumbs
              props={{
                routes: props.routes,
              }}
            />
          )}
          <WorkflowTitle workflow={props.workflow} pushEvent={pushEvent} />
        </div>
        <WorkflowEditor pushEvent={pushEvent} props={props} />
      </ReactFlowProvider>
    </div>
  )
}

export default WorkflowEditorPage
