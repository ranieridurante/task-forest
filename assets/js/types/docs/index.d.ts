import type { TWorkflow } from 'types/workflow'
import type { TShortcut } from 'types/app'

type TProgrammingLanguage =
  | 'bash'
  | 'python'
  | 'javascript'
  | 'java'
  | 'spring'
  | 'elixir'

type TAPIDocumentationPageProps = {
  workflow: TWorkflow
  company_auth_token: string
  shortcuts: TShortcut[]
}

type TAuthTokenPageProps = {
  company_auth_token: string
}

type TWorkflowAPIEndpointDocsCodeBlock = {
  workflow: TWorkflow
  language: TProgrammingLanguage
  company_auth_token: string
}
