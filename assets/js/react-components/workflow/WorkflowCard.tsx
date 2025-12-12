import React from 'react'
import {
  Button,
  Card,
  CardBody,
  CardFooter,
  Dropdown,
  DropdownItem,
  DropdownMenu,
  DropdownSection,
  DropdownTrigger,
  Link,
  Spacer,
  Tooltip,
} from '@nextui-org/react'
import WorkflowGraphPreview from './WorkflowGraphPreview'
import type { TWorkflowCardProps } from 'types/workflow'

/**
 * Component that represents a Workflow card, with its preview.
 * @constructor
 */
const WorkflowCard: React.FC<TWorkflowCardProps> = ({
  workflow,
  taskWithProviderStyles,
  onOpenDeleteWorkflowModal,
  onOpenCreateWorkflowTemplateModal,
  isPlombAdmin,
  handleDuplicateWorkflow,
}) => (
  <Card fullWidth={true} shadow='sm' isHoverable>
    <CardBody className='overflow-visible p-0'>
      <Link href={`/workflows/${workflow.id}`} className='relative'>
        <div className='w-full h-full absolute top-0 left-0 z-10'></div>
        <WorkflowGraphPreview
          graph={workflow.graph}
          taskWithProviderStyles={taskWithProviderStyles}
        />
      </Link>
    </CardBody>
    <CardFooter className='justify-between'>
      <div className='text-small text-start'>
        {workflow.workflow_template && isPlombAdmin && (
          <Tooltip
            classNames={{
              base: 'pointer-events-none',
            }}
            closeDelay={0}
            content='Workflow Template'
          >
            <iconify-icon
              icon='carbon:license-maintenance-draft'
              width='16'
              height='16'
              class='text-danger-500 mr-1'
            />
          </Tooltip>
        )}
        <b>{workflow.name}</b>
        <p className='text-default-500 italic'>
          {workflow.description || 'No description.'}
        </p>
      </div>
      <Dropdown placement='top-end'>
        <DropdownTrigger>
          <Button
            isIconOnly
            size='lg'
            color='primary'
            className='rounded-md'
            startContent={
              <iconify-icon icon='tabler:dots' width='32' height='32' />
            }
            variant='light'
          />
        </DropdownTrigger>
        <DropdownMenu
          variant='faded'
          aria-label='Dropdown menu with description'
        >
          <DropdownSection showDivider>
            <DropdownItem
              key='edit'
              href={`/workflows/${workflow.id}`}
              startContent={
                <iconify-icon icon='tabler:edit' width='16' height='16' />
              }
            >
              Edit Workflow
            </DropdownItem>
            <DropdownItem
              key='duplicate'
              onPress={() => handleDuplicateWorkflow(workflow.id)}
              startContent={
                <iconify-icon
                  icon='famicons:duplicate'
                  width='16'
                  height='16'
                />
              }
            >
              Duplicate Workflow
            </DropdownItem>
            {!workflow.workflow_template && isPlombAdmin && (
              <DropdownItem
                key='create-template'
                onPress={() => onOpenCreateWorkflowTemplateModal(workflow)}
                startContent={
                  <iconify-icon
                    icon='carbon:license-maintenance-draft'
                    width='16'
                    height='16'
                  />
                }
              >
                Create Workflow Template
              </DropdownItem>
            )}
          </DropdownSection>
          <DropdownSection showDivider>
            {workflow.workflow_template && isPlombAdmin && (
              <DropdownItem
                key='go-to-template'
                href={`/market/workflow-templates/${workflow.workflow_template.slug}`}
                startContent={
                  <iconify-icon
                    icon='carbon:license-maintenance-draft'
                    width='16'
                    height='16'
                  />
                }
              >
                Workflow Template
              </DropdownItem>
            )}
            {isPlombAdmin && (
              <DropdownItem
                key='magic-forms'
                href={`/workflows/${workflow.id}/magic-forms`}
                startContent={
                  <iconify-icon
                    icon='fluent:form-sparkle-20-filled'
                    width='16'
                    height='16'
                  />
                }
              >
                Magic Forms
              </DropdownItem>
            )}
            <DropdownItem
              key='app'
              href={`/workflows/${workflow.id}/app-dashboard`}
              startContent={
                <iconify-icon
                  icon='grommet-icons:console'
                  width='16'
                  height='16'
                />
              }
            >
              App Dashboard
            </DropdownItem>
            <DropdownItem
              key='docs'
              href={`/workflows/${workflow.id}/api-documentation`}
              startContent={
                <iconify-icon
                  icon='material-symbols:docs'
                  width='16'
                  height='16'
                />
              }
            >
              API Documentation
            </DropdownItem>
          </DropdownSection>
          <DropdownSection>
            <DropdownItem
              key='delete'
              className='text-danger'
              color='danger'
              startContent={
                <iconify-icon icon='tabler:trash' width='16' height='16' />
              }
              onPress={() => onOpenDeleteWorkflowModal(workflow)}
            >
              Delete Workflow
            </DropdownItem>
          </DropdownSection>
        </DropdownMenu>
      </Dropdown>
    </CardFooter>
  </Card>
)

export default WorkflowCard
