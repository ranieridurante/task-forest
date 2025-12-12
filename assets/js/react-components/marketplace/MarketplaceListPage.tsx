import React, { useState } from 'react'
import {
  Avatar,
  AvatarGroup,
  Button,
  Card,
  CardFooter,
  Chip,
  Input,
  Spacer,
  Tooltip,
} from '@nextui-org/react'
import PageTitle from 'react-components/common/PageTitle'

import { Link } from '@nextui-org/react'
import { type TMarketplaceListPageProps } from 'types/marketplace'

const MarketplaceListPage: React.FC<
  LiveReactComponentProps<TMarketplaceListPageProps>
> = ({
  props: { page_data, workflow_templates, providers_by_slug },
  pushEvent,
}) => {
  const [searchQuery, setSearchQuery] = useState('')

  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSearchQuery(event.target.value)
  }

  return (
    <>
      <Spacer y={4} />
      <PageTitle title={page_data.title} icon='fluent:store-24-filled' />
      <Spacer y={1} />
      {page_data.image_url && (
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
                src={page_data.image_url}
                alt={page_data.title}
                className='w-full h-full object-cover'
              />
              {page_data.short_description && (
                <CardFooter className='min-h-20 justify-center flex flex-row bg-black/30 border-black/20 border-1 overflow-hidden py-1 absolute before:rounded-xl rounded-large bottom-1 w-[calc(100%_-_8px)] shadow-small ml-1 z-10'>
                  <div className='flex items-center justify-evenly mr-4'>
                    <p className='text-m text-right text-white'>
                      {page_data.short_description}
                    </p>
                  </div>
                </CardFooter>
              )}
            </Card>
          </div>
          <Spacer y={8} />
        </>
      )}
      {workflow_templates.length == 0 && (
        <div className='flex items-center justify-center align-items-center h-[40vh]'>
          <p className='text-lg text-plombLightkBrown-500'>
            There are no templates.
          </p>
        </div>
      )}
      <div className='flex grid grid-cols-1 lg:grid-cols-2 place-items-center gap-6'>
        {workflow_templates.map((template) => (
          <>
            <Card
              key={template.id}
              fullWidth
              shadow='sm'
              isHoverable
              isPressable
              className='bg-plombYellow-100'
              onPress={() => {
                window.location.href = `/market/workflow-templates/${template.slug}`
              }}
            >
              <CardFooter className='mx-4 my-2 items-center justify-between flex flex-row'>
                <div className='flex flex-row'>
                  <AvatarGroup
                    isGrid
                    max={6}
                    size='sm'
                    isBordered
                    className='grid-cols-6 place-items-center gap-1'
                  >
                    {template.provider_slugs.split(',').map((provider_slug) => {
                      const provider = providers_by_slug[provider_slug]
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
                            />
                          </Tooltip>
                        </>
                      )
                    })}
                  </AvatarGroup>
                </div>
                <div className='flex flex-row justify-end items-center pr-[2rem]'>
                  <div className='flex flex-col text-right'>
                    <h3 className='text-lg font-bold'>{template.name}</h3>
                    <p className='text-sm'>{template.short_description}</p>
                  </div>
                  <Spacer x={4} />
                  <Button
                    color='primary'
                    variant='solid'
                    as={Link}
                    href={`/market/workflow-templates/${template.slug}`}
                  >
                    Get
                  </Button>
                </div>
              </CardFooter>
            </Card>
          </>
        ))}
      </div>
    </>
  )
}

export default MarketplaceListPage
