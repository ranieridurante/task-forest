# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TaskForest.Repo.insert!(%TaskForest.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias TaskForest.Accounts.Company
alias TaskForest.Accounts.ApiToken
alias TaskForest.Repo
alias TaskForest.Tasks.Task
alias TaskForest.Workflows.Workflow
alias TaskForest.Workflows.WorkflowConfig

company =
  Repo.insert!(%Company{
    name: "Sophinauta",
    ai_tokens: %{
      "openai" => %{"OPENAI_API_KEY" => "CHANGE_ME"}
    }
  })

Repo.insert!(%ApiToken{
  company_id: company.id,
  token: "DEV-AUTH-TOKEN",
  alias: "Dev Token"
})

workflow =
  Repo.insert!(%Workflow{
    company_id: company.id,
    name: "LangTuner: Translate",
    description: "Translate text from one language to another",
    config: %WorkflowConfig{
      model_provider: "openai",
      model_id: "gpt-4-turbo",
      model_params: %{
        response_format: %{"type" => "json_object"},
        temperature: 0.7
      }
    }
  })

prompt = """
You're an expert translator between >>LANG<< and >>TARGET_LANG<<.
Translate the following text:

TEXT
####
>>TEXT<<

Return the translation as a JSON using the following format:

RESPONSE FORMAT
####
{
  "translated_text": <translated_text>
}
"""

Repo.insert!(%Task{
  workflow_id: workflow.id,
  name: "Translate",
  prompt: prompt,
  inputs_definition: %{
    "text" => %{"type" => "string"},
    "lang" => %{"type" => "string"},
    "target_lang" => %{"type" => "string"}
  },
  outputs_definition: %{
    "translated_text" => %{"type" => "string"}
  },
  phase: 1
})
