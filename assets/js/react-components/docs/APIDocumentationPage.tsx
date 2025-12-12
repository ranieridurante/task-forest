import React from 'react'
import {
  Button,
  Card,
  CardBody,
  Input,
  Modal,
  ModalBody,
  ModalContent,
  ModalFooter,
  ModalHeader,
  Spacer,
} from '@nextui-org/react'
import { Tab, Tabs } from '@nextui-org/tabs'
import PageTitle from '../common/PageTitle'
import WorkflowAPIEndpointDocsCodeBlock from './WorkflowAPIEndpointDocsCodeBlock'
import type { TAPIDocumentationPageProps } from 'types/docs'
import DashboardShortcuts from '../app/DashboardShortcuts'

const DEFAULT_AUTH_TOKEN = 'AUTH_TOKEN'

const TabWithIcon = ({ icon, label }: { icon: string; label: string }) => (
  <div className='flex items-center space-x-2'>
    <iconify-icon icon={icon} width='24' height='24' />
    <span>{label}</span>
  </div>
)

const APIDocumentationPage: React.FC<
  LiveReactComponentProps<TAPIDocumentationPageProps>
> = ({ props: { workflow, company_auth_token, shortcuts }, pushEvent }) => {
  const [isModalOpen, setIsModalOpen] = React.useState(false)
  const [copied, setCopied] = React.useState(false)
  const [companyAuthToken, setCompanyAuthToken] =
    React.useState(company_auth_token)

  const handleGenerateAuthToken = () => {
    companyAuthToken === DEFAULT_AUTH_TOKEN
      ? sendGenerateAuthTokenEvent()
      : setIsModalOpen(true)
  }

  const sendGenerateAuthTokenEvent = () => {
    pushEvent('react.generate_auth_token', {})
  }

  const onConfirm = () => {
    sendGenerateAuthTokenEvent()
    setIsModalOpen(false)
  }

  const onClose = () => setIsModalOpen(false)

  React.useEffect(() => {
    const updateCompanyAuthToken = (e: Event) => {
      const server_event_data = (e as CustomEvent).detail
      setCompanyAuthToken(server_event_data.company_auth_token)
    }

    window.addEventListener(
      'phx:server.update_company_auth_token',
      updateCompanyAuthToken
    )

    return () => {
      window.removeEventListener(
        'phx:server.update_company_auth_token',
        updateCompanyAuthToken
      )
    }
  }, [pushEvent])

  return (
    <>
      <PageTitle title='API Documentation' icon='ant-design:api-outlined' />
      <DashboardShortcuts shortcuts={shortcuts} />

      <Spacer y={4} />
      <div>
        <div className='flex flex-row items-center mb-4'>
          <iconify-icon icon='solar:code-outline' width='22' height='22' />
          <h2 className='text-xl grow ml-2'>Code Snippets</h2>
        </div>
        <Card>
          <CardBody>
            <Tabs color='primary' variant='solid'>
              <Tab
                key='bash'
                title={<TabWithIcon icon='devicon:bash' label='Bash' />}
              >
                <WorkflowAPIEndpointDocsCodeBlock
                  workflow={workflow}
                  language='bash'
                  company_auth_token={companyAuthToken}
                />
              </Tab>
              <Tab
                key='python'
                title={<TabWithIcon icon='devicon:python' label='Python' />}
              >
                <WorkflowAPIEndpointDocsCodeBlock
                  workflow={workflow}
                  language='python'
                  company_auth_token={companyAuthToken}
                />
              </Tab>
              <Tab
                key='nodejs'
                title={<TabWithIcon icon='devicon:nodejs' label='Node.js' />}
              >
                <WorkflowAPIEndpointDocsCodeBlock
                  workflow={workflow}
                  language='javascript'
                  company_auth_token={companyAuthToken}
                />
              </Tab>
              <Tab
                key='java'
                title={<TabWithIcon icon='devicon:java' label='Java' />}
              >
                <WorkflowAPIEndpointDocsCodeBlock
                  workflow={workflow}
                  language='java'
                  company_auth_token={companyAuthToken}
                />
              </Tab>
              <Tab
                key='spring'
                title={
                  <TabWithIcon icon='devicon:spring' label='Spring Boot' />
                }
              >
                <WorkflowAPIEndpointDocsCodeBlock
                  workflow={workflow}
                  language='spring'
                  company_auth_token={companyAuthToken}
                />
              </Tab>
              <Tab
                key='elixir'
                title={<TabWithIcon icon='devicon:elixir' label='Elixir' />}
              >
                <WorkflowAPIEndpointDocsCodeBlock
                  workflow={workflow}
                  language='elixir'
                  company_auth_token={companyAuthToken}
                />
              </Tab>
            </Tabs>
          </CardBody>
        </Card>
      </div>

      <Modal isOpen={isModalOpen} onClose={onClose}>
        <ModalContent>
          <ModalHeader>Confirm Action</ModalHeader>
          <ModalBody>
            Are you sure you want to generate a new auth token? The current
            token will be invalidated.
          </ModalBody>
          <ModalFooter>
            <Button variant='light' onPress={onClose}>
              Cancel
            </Button>
            <Button color='primary' onPress={onConfirm}>
              Generate
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </>
  )
}

export default APIDocumentationPage
