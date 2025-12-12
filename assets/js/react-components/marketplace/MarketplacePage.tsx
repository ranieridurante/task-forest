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

import { Swiper, SwiperSlide } from 'swiper/react'
import { Autoplay, Pagination, Navigation } from 'swiper/modules'
import { Link } from '@nextui-org/react'

const MarketplacePage: React.FC<
  LiveReactComponentProps<TMarketplacePageProps>
> = ({
  props: { categories, providers_by_slug, collections, main_collections },
  pushEvent,
}) => {
  const VISIBLE_COLLECTION_SIZE = 3

  const [searchQuery, setSearchQuery] = useState('')

  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSearchQuery(event.target.value)
  }

  // TODO: Add support for pagination
  const submitSearch = () => {
    pushEvent('react.search', {
      search_term: searchQuery,
    })

    setSearchQuery('')
  }

  return (
    <>
      <div className='flex flex-row justify-between'>
        <PageTitle title='Market' icon='fluent:store-24-filled' />
        <div className='flex justify-end mb-4'>
          <Input
            clearable
            underlined
            placeholder='Search'
            value={searchQuery}
            onChange={handleSearchChange}
            minLength={3}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault()
                submitSearch()
              }
            }}
            startContent={
              <iconify-icon
                icon='bitcoin-icons:search-outline'
                alt='Search Icon'
                width='24'
                height='24'
              />
            }
          />
        </div>
      </div>
      <div className='mb-4'>
        <div className='flex flex-wrap gap-2 my-2'>
          {categories.map((category) => (
            <>
              <Chip
                color='primary'
                size='lg'
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
      <div className='mb-4'>
        <Swiper
          style={{
            '--swiper-navigation-color': '#D9318B',
            '--swiper-pagination-color': '#D9318B',
          }}
          autoplay={{
            delay: 3500,
            disableOnInteraction: false,
          }}
          slidesPerView={1}
          spaceBetween={30}
          loop={true}
          pagination={{
            clickable: true,
          }}
          navigation={true}
          modules={[Autoplay, Pagination, Navigation]}
          className='MainSwiper'
        >
          {main_collections.map((collection) => (
            <SwiperSlide key={collection.id}>
              <Card
                isFooterBlurred
                fullWidth
                shadow='sm'
                isHoverable
                className='border-none h-[460px]'
              >
                <h2 className='absolute top-2 left-2 bg-[#D9318B]/90 px-2 py-1 text-white rounded text-3xl font-bold'>
                  {collection.title}
                </h2>
                <img
                  src={collection.image_url}
                  alt={collection.title}
                  className='w-full h-full object-cover'
                />
                <CardFooter className='min-h-20 justify-between flex flex-row bg-black/30 border-black/20 border-1 overflow-hidden py-1 absolute before:rounded-xl rounded-large bottom-1 w-[calc(100%_-_8px)] shadow-small ml-1 z-10'>
                  <div className='flex ml-4 my-2 items-center justify-start w-[50%]'>
                    <AvatarGroup isBordered>
                      {collection.featured_providers.map((featuredProvider) => {
                        const provider =
                          providers_by_slug[featuredProvider.provider_slug]
                        return (
                          <>
                            <Tooltip
                              placement='top'
                              content={`See more using ${provider.name}`}
                              closeDelay={0}
                            >
                              <Avatar
                                size='lg'
                                radius='full'
                                as={Link}
                                href={`/market/providers/${provider.slug}`}
                                key={provider.slug}
                                src={provider.logo}
                                alt={provider.name}
                                className='w-12 h-12 object-cover !rounded'
                              />
                            </Tooltip>
                          </>
                        )
                      })}
                    </AvatarGroup>
                  </div>
                  <div className='flex items-center justify-evenly mr-4'>
                    <p className='text-m text-right text-white'>
                      {collection.short_description}
                    </p>
                    <Spacer x={4} />
                    <Button
                      color='primary'
                      variant='solid'
                      className='bg-plombPink-500'
                      as={Link}
                      href={`/market/collections/${collection.slug}`}
                    >
                      See Collection
                    </Button>
                  </div>
                </CardFooter>
              </Card>
            </SwiperSlide>
          ))}
        </Swiper>
      </div>
      <Spacer y={8} />
      <div className='flex grid grid-cols-1 lg:grid-cols-2 place-items-center gap-6'>
        {collections.map((collection) => (
          <div key={collection.id} className='flex flex-col w-full px-4 py-6'>
            <div className='flex flex-row justify-between'>
              <h2 className='text-xl font-bold my-2'>{collection.title}</h2>
              <Link href={`/market/collections/${collection.slug}`}>
                See all
              </Link>
            </div>
            <div className='flex flex-col grid-cols-1 gap-3 w-full'>
              {collection.workflow_templates
                .slice(0, VISIBLE_COLLECTION_SIZE)
                .map((template) => (
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
                            {template.provider_slugs
                              .split(',')
                              .map((provider_slug) => {
                                const provider =
                                  providers_by_slug[provider_slug]
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
                            <h3 className='text-lg font-bold'>
                              {template.name}
                            </h3>
                            <p className='text-sm'>
                              {template.short_description}
                            </p>
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
          </div>
        ))}
      </div>
    </>
  )
}

export default MarketplacePage
