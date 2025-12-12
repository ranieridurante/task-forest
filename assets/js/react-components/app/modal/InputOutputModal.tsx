import React from 'react'
import {
  Button,
  Divider,
  Modal,
  ModalBody,
  ModalContent,
  ModalFooter,
  ModalHeader,
} from '@nextui-org/react'
import { Tab, Tabs } from '@nextui-org/tabs'
import type { TInputOutputModalProps } from 'types/app'
import '@andypf/json-viewer'

const PLOMB_JSON_VIEWER_THEME =
  '{"base00": "#4B2E2E", "base01": "#4B2E2E", "base02": "#4B2E2E", "base03": "#4B2E2E", "base04": "#4B2E2E", "base05": "#e5bdbd", "base06": "#e5bdbd", "base07": "#e5bdbd", "base08": "#8C4C47", "base09": "#ffc57d", "base0A": "#CD5D57", "base0B": "#E56B66", "base0C": "#E56B66", "base0D": "#ff7b75", "base0E": "#ff7b75", "base0F": "#ff7b75"}'

/**
 * Component that represents a modal to show the inputs/outputs of a run or a scheduled trigger.
 * Redesigned with a modern console-inspired theme.
 */
const InputOutputModal: React.FC<TInputOutputModalProps> = ({
  isOpen,
  onClose,
  onOpenChange,
  execution,
  trigger,
  activeTab,
}) => {
  const handleCopyToClipboard = (data: object) => {
    navigator.clipboard.writeText(JSON.stringify(data, null, 2))
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      onOpenChange={onOpenChange}
      size='3xl'
      scrollBehavior='inside'
      placement='top-center'
      className='bg-white'
    >
      <ModalContent>
        <ModalHeader className='flex-col gap-2 px-4 py-3 bg-white border-b border-[#4B2E2E]/20'>
          <div className='flex flex-row items-center w-full'>
            <iconify-icon
              icon={
                trigger === undefined
                  ? 'ix:runtime-settings'
                  : 'akar-icons:schedule'
              }
              width='32'
              height='32'
              className='text-plombDarkBrown-500'
            />
            {execution && (
              <div className='ml-2'>
                <p className='text-lg font-bold text-plombDarkBrown-500'>
                  Execution ID:{' '}
                  <span className='text-plombDarkBrown-300'>
                    {execution.id}
                  </span>
                </p>
              </div>
            )}
            {trigger && (
              <div className='ml-2'>
                <p className='text-lg font-bold text-plombDarkBrown-500'>
                  Trigger: {trigger.name}
                </p>
              </div>
            )}
          </div>
        </ModalHeader>
        <ModalBody className='bg-white p-4'>
          <div className='bg-white p-4 rounded-lg border border-[#4B2E2E]/20'>
            <Tabs
              aria-label='Input/Output'
              defaultSelectedKey={activeTab}
              variant='underlined'
              classNames={{
                tabList:
                  'gap-4 relative rounded-none p-0 border-b border-[#4B2E2E]/20',
                cursor: 'w-full bg-[#4B2E2E]',
                tab: 'max-w-fit px-0 h-12',
                tabContent: 'group-data-[selected=true]:text-[#4B2E2E]',
              }}
            >
              <Tab
                key='input'
                title={
                  <div className='flex items-center gap-2'>
                    <iconify-icon icon='mdi:input' width='22' height='22' />
                    <span className='text-lg'>Inputs</span>
                  </div>
                }
              >
                <div className='bg-white p-2 rounded-lg'>
                  <div className='flex justify-end mb-2'>
                    <Button
                      id='copy-btn-inputs'
                      size='sm'
                      variant='bordered'
                      className='text-[#4B2E2E] border-[#4B2E2E]'
                      onPress={() => {
                        handleCopyToClipboard(
                          execution?.inputs || trigger?.inputs || {}
                        )
                        const button =
                          document.getElementById('copy-btn-inputs')
                        button.innerText = 'Copied!'
                        const parent = document.activeElement?.parentElement
                        parent?.appendChild(button)
                      }}
                      startContent={
                        <iconify-icon
                          icon='material-symbols:content-copy'
                          width='20'
                          height='20'
                        />
                      }
                    >
                      Copy
                    </Button>
                  </div>

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
                      data={JSON.stringify(
                        execution?.inputs || trigger?.inputs || {}
                      )}
                    />
                  </div>
                </div>
              </Tab>
              <Tab
                key='output'
                title={
                  <div className='flex items-center gap-2'>
                    <iconify-icon icon='mdi:output' width='22' height='22' />
                    <span className='text-lg'>Outputs</span>
                  </div>
                }
                isDisabled={trigger !== undefined}
              >
                <div className='bg-white p-2 rounded-lg'>
                  <div className='flex justify-end mb-2'>
                    <Button
                      id='copy-btn-outputs'
                      size='sm'
                      variant='bordered'
                      className='text-[#4B2E2E] border-[#4B2E2E]'
                      onPress={() => {
                        handleCopyToClipboard(execution?.outputs || {})
                        const button =
                          document.getElementById('copy-btn-outputs')
                        if (button) button.innerText = 'Copied!'
                        const parent = document.activeElement?.parentElement
                        parent?.appendChild(button)
                      }}
                      startContent={
                        <iconify-icon
                          icon='material-symbols:content-copy'
                          width='20'
                          height='20'
                        />
                      }
                    >
                      <span>Copy</span>
                    </Button>
                  </div>
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
                      data={JSON.stringify(execution?.outputs || {})}
                    />
                  </div>
                </div>
              </Tab>
            </Tabs>
          </div>
        </ModalBody>
      </ModalContent>
    </Modal>
  )
}

export default InputOutputModal
