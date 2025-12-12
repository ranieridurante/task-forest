import type { TProviderWithStoredKeys } from 'types/provider'

type TMarketplacePageProps = {
  categories: TCategory[]
  providers_by_slug: { [key: string]: TProvider }
  collections: TCollection[]
  main_collections: TCollection[]
}

type TMarketplaceListPageProps = {
  page_data: TPageData
  workflow_templates: TWorkflowTemplatePreview[]
  providers_by_slug: { [key: string]: TProvider }
}

type TWorkflowTemplatePageProps = {
  workflow_template: TWorkflowTemplate
  connected_providers_by_slug: { [key: string]: TProviderWithStoredKeys[] }
  providers_by_slug: { [key: string]: TProvider[] }
  categories: TCategory[]
  is_owner: boolean
}

type TPageData = {
  title: string
  short_description: string
  image_url: string
  markdown_description: string
  slug: string
}

type TCategory = {
  id: string
  name: string
  icon: string
  slug: string
}

type TMainCollection = {
  id: string
  title: string
  short_description: string
  image_url: string
  slug: string
  markdown_description: string
  featured_providers: TFeaturedProvider[]
  workflow_templates: TWorkflowTemplatePreview[]
}

type TCollection = {
  id: string
  title: string
  slug: string
  featured_providers: TFeaturedProvider[]
  workflow_templates: TWorkflowTemplatePreview[]
}

type TWorkflowTemplatePreview = {
  id: string
  name: string
  short_description: string
  featured: boolean
  provider_slugs: string
  slug: string
}

type TWorkflowTemplate = TWorkflowTemplatePreview & {
  markdown_instructions: string
  markdown_description: string
  image_url: string
}

type TFeaturedProvider = {
  provider_slug: string
}
