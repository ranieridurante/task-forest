import React, { useState, useEffect } from 'react'
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
} from '@nextui-org/react'
import PageTitle from '../common/PageTitle'
import type { TAuthTokenPageProps } from 'types/docs'

const DEFAULT_AUTH_TOKEN = 'AUTH_TOKEN'

const AuthTokenPage: React.FC<LiveReactComponentProps<TAuthTokenPageProps>> = ({
  props: { company_auth_token },
  pushEvent,
}) => {
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [copied, setCopied] = useState(false)
  const [companyAuthToken, setCompanyAuthToken] = useState(company_auth_token)

  const showInput = companyAuthToken && companyAuthToken !== DEFAULT_AUTH_TOKEN

  const sendGenerateAuthTokenEvent = () => {
    pushEvent('react.generate_auth_token', {})
  }

  const handleGenerateAuthToken = () => {
    companyAuthToken === DEFAULT_AUTH_TOKEN
      ? sendGenerateAuthTokenEvent()
      : setIsModalOpen(true)
  }

  const onConfirm = () => {
    sendGenerateAuthTokenEvent()
    setIsModalOpen(false)
  }

  useEffect(() => {
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
    <div className=''>
      <PageTitle title='API Keys' icon='material-symbols:key-outline-rounded' />
      <Card className=''>
        <CardBody className='flex flex-col gap-4'>
          <div className='flex items-center gap-4'>
            <Input
              readOnly
              value={showInput ? companyAuthToken : ''}
              variant='bordered'
              label='API Key'
              placeholder='No API key has been generated yet'
              className='flex-1'
              endContent={
                showInput && (
                  <Button
                    isIconOnly
                    variant='light'
                    onClick={() => {
                      navigator.clipboard.writeText(companyAuthToken)
                      setCopied(true)
                      setTimeout(() => setCopied(false), 1500)
                    }}
                  >
                    <iconify-icon
                      icon='material-symbols:content-copy'
                      width='20'
                      height='20'
                    />
                  </Button>
                )
              }
            />
            <Button
              color='primary'
              variant='solid'
              onClick={handleGenerateAuthToken}
              startContent={
                <iconify-icon
                  icon='streamline-ultimate:crypto-encryption-key'
                  width='20'
                  height='20'
                />
              }
            >
              {showInput ? 'Generate New API Key' : 'Generate API Key'}
            </Button>
          </div>
          {copied && (
            <p className='text-sm text-success'>API key copied to clipboard!</p>
          )}
        </CardBody>
      </Card>

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)}>
        <ModalContent>
          <ModalHeader className='flex items-center gap-2'>
            <iconify-icon
              icon='material-symbols:warning-rounded'
              className='text-warning'
              width='24'
              height='24'
            />
            Confirm Action
          </ModalHeader>
          <ModalBody>
            Are you sure you want to generate a new API key? The current API key
            will be invalidated immediately.
          </ModalBody>
          <ModalFooter>
            <Button variant='light' onPress={() => setIsModalOpen(false)}>
              Cancel
            </Button>
            <Button color='primary' onPress={onConfirm}>
              Generate New API Key
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </div>
  )
}

export default AuthTokenPage
