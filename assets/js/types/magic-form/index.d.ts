export type TMagicFormCard = {
  id: string
  name: string
  config: TMagicFormConfig
  views_count: number
  submissions_count: number
}

export type TMagicFormConfig = {
  is_public?: boolean
}

export type TMagicFormPageProps = {
  magic_forms: TMagicFormCard[]
}
