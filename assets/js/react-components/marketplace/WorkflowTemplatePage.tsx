import type { Key } from 'react'
import React, { useState } from 'react'
import {
  Avatar,
  AvatarGroup,
  Button,
  Card,
  CardBody,
  CardFooter,
  CardHeader,
  Chip,
  Input,
  Spacer,
  Tab,
  Tabs,
  Tooltip,
} from '@nextui-org/react'
import PageTitle from 'react-components/common/PageTitle'

import { Link } from '@nextui-org/react'
import { parseMarkdown } from 'util'

const WorkflowTemplatePage: React.FC<
  LiveReactComponentProps<TWorkflowTemplatePageProps>
> = ({
  props: {
    workflow_template,
    providers_by_slug,
    connected_providers_by_slug,
    categories,
    is_owner,
  },
  pushEvent,
}) => {
  const [selected, setSelected] = useState('about')

  const handleGetTemplate = () => {
    pushEvent('react.create_workflow_from_template', {
      workflow_template_id: workflow_template.id,
    })
  }

  const handleDeleteTemplate = () => {
    pushEvent('react.delete_workflow_template', {
      workflow_template_id: workflow_template.id,
    })
  }

  const handleTextSelection = (key: Key) => {
    setSelected(key.toString())
    const element = document.getElementById('text')
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' })
    }
  }

  const markdownOpts = {
    overrides: {
      h1: {
        component: 'h1',
        props: {
          className: 'text-xl font-bold text-plombLightBrown-200 mb-1',
        },
      },
      h2: {
        component: 'h2',
        props: {
          className: 'text-lg font-bold text-plombLightBrown-200 mb-1',
        },
      },
      h3: {
        component: 'h3',
        props: {
          className: 'text-md font-bold text-plombLightBrown-200 mb-1',
        },
      },
      p: {
        component: 'p',
        props: {
          className: 'text-base text-plombLightBrown-200 text-justify my-1',
        },
      },
      a: {
        component: 'a',
        props: {
          target: '_blank',
          className: 'text-base text-plombPink-500 underline',
        },
      },
      li: {
        component: 'li',
        props: {
          className: 'text-base text-plombLightBrown-200 mb-1',
        },
      },
      ol: {
        component: 'ol',
        props: {
          className:
            'list-decimal list-inside text-base text-plombLightBrown-200 mb-1',
        },
      },
      ul: {
        component: 'ul',
        props: {
          className:
            'list-disc list-inside text-base text-plombLightBrown-200 mb-1',
        },
      },
      hr: {
        component: 'hr',
        props: {
          className: 'border-none h-[1px] bg-gray-500 w-1/2 my-5 mx-auto',
        },
      },
    },
  }

  return (
    <>
      <Spacer y={4} />
      <div className='flex flex-row justify-between items-center'>
        <div>
          <div className='flex flex-row items-center justify-start'>
            <h1 className='text-3xl font-bold'>{workflow_template.name}</h1>
            <Spacer x={1} />
            <Tooltip placement='top' content='Featured' closeDelay={0}>
              <iconify-icon
                icon='fluent:ribbon-star-24-filled'
                alt='Search Icon'
                width='24'
                height='24'
                class='text-plombPink-500 text-baseline'
              />
            </Tooltip>
          </div>
          <p className='text-xl'>{workflow_template.short_description}</p>
        </div>

        <div>
          {!is_owner && (
            <Button
              color='primary'
              variant='solid'
              onPress={handleGetTemplate}
              className='bg-plombPink-500'
            >
              Get
            </Button>
          )}
          {is_owner && (
            <>
              <Button
                color='danger'
                variant='solid'
                onPress={handleDeleteTemplate}
              >
                Delete
              </Button>
            </>
          )}
        </div>
      </div>
      <div className='flex flex-col gap-2'>
        <Spacer y={2} />
        <div className='flex flex-row'>
          <AvatarGroup
            isGrid
            max={6}
            size='sm'
            isBordered
            className='grid-cols-6 place-items-center gap-1'
          >
            {workflow_template.provider_slugs
              .split(',')
              .map((provider_slug) => {
                const provider = providers_by_slug[provider_slug]

                const connected_provider =
                  connected_providers_by_slug[provider_slug]

                const is_connected =
                  connected_provider !== undefined || provider.slug == 'plomb'

                const border_color = is_connected
                  ? 'outline-4 outline-plombPink-500'
                  : ''

                return (
                  <>
                    <Tooltip
                      placement='top'
                      content={`See more using ${provider.name}`}
                      closeDelay={0}
                    >
                      <Avatar
                        size='sm'
                        radius='full'
                        as={Link}
                        href={`/market/providers/${provider.slug}`}
                        key={provider.slug}
                        src={provider.logo}
                        alt={provider.name}
                        classNames={{
                          base: border_color,
                        }}
                      />
                    </Tooltip>
                  </>
                )
              })}
          </AvatarGroup>
        </div>
        <div className='flex flex-wrap gap-2 my-2'>
          {categories.map((category) => (
            <>
              <Chip
                color='primary'
                size='md'
                variant='flat'
                radius='small'
                as={Link}
                href={`/market/categories/${category.slug}`}
                startContent={
                  <iconify-icon
                    icon={category.icon}
                    alt={category.name}
                    width='24'
                    height='24'
                  />
                }
              >
                {category.name}
              </Chip>
            </>
          ))}
        </div>
      </div>
      <Spacer y={2} />
      {workflow_template.image_url && (
        <>
          <div className='mb-4'>
            <Card
              isFooterBlurred
              fullWidth
              shadow='sm'
              isHoverable
              className='border-none'
            >
              <img
                src={workflow_template.image_url}
                alt={workflow_template.name}
                className='w-full h-full object-cover'
              />
            </Card>
          </div>
          <Spacer y={8} />
        </>
      )}
      <div className='flex grid grid-cols-1 lg:grid-cols-1 place-items-center gap-6'>
        <Card
          id='text'
          key={workflow_template.id}
          fullWidth
          shadow='sm'
          className='bg-plombYellow-100 p-8'
        >
          <Tabs
            fullWidth
            defaultSelectedKey={selected}
            onSelectionChange={handleTextSelection}
            shouldSelectOnPressUp={false}
            disableAnimation={true}
          >
            <Tab key='about' title='About'>
              <CardBody>
                {parseMarkdown(
                  workflow_template.markdown_description,
                  markdownOpts
                )}
              </CardBody>
            </Tab>
            <Tab key='instructions' title='Instructions'>
              <CardBody>
                {parseMarkdown(
                  workflow_template.markdown_instructions,
                  markdownOpts
                )}
              </CardBody>
            </Tab>
          </Tabs>
        </Card>
      </div>
    </>
  )
}

export default WorkflowTemplatePage
