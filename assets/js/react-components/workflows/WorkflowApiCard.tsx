import React from 'react'
import {
  Card,
  CardBody,
  CardFooter,
  Link,
  Button,
  Accordion,
  AccordionItem,
} from '@nextui-org/react'
import CodeTabs from '../CodeTabs'
import WorkflowFormButton from './WorkflowFormButton'
import GraphPreview from '../GraphPreview'

type TWorkflowInputsDefinition = {
  [key: string]: any
}

type TWorkflowData = {
  id: string
  name: string
  description?: string
  graph: string
  inputs_definition: TWorkflowInputsDefinition
  api_endpoint: string
  company_id: string
}

type TWorkflowApiCardProps = {
  workflow: TWorkflowData
}

export default function App({
  props,
  pushEvent,
}: LiveReactComponentProps<TWorkflowApiCardProps>) {
  const sampleData = Object.keys(props.workflow.inputs_definition).reduce(
    (acc, key) => {
      const type = props.workflow.inputs_definition[key].type

      const typeToShow = type == 'text' ? 'string' : type

      acc[key] = 'a valid ' + typeToShow
      return acc
    },
    {}
  )

  const codeBlocks = buildCodeBlocks(props.workflow.api_endpoint, {
    inputs: sampleData,
  })

  return (
    <Card className='w-full shadow-md my-1 bg-plombYellow-300'>
      <CardBody className='flex flex-row'>
        <CodeTabs props={codeBlocks} />
      </CardBody>
    </Card>
  )
}

function buildCodeBlocks(
  api_endpoint: String,
  workflow_inputs_definition: TWorkflowInputsDefinition
) {
  return [
    {
      title: 'Bash',
      language: 'bash',
      content: `
# Define the URL and headers
execute_workflow_url='${api_endpoint}'
headers='Content-Type: application/json'

# Define the sample JSON body
sample_data='${JSON.stringify(workflow_inputs_definition, null, 2)}'

# Make the POST request
response=$(curl -s -X POST "$execute_workflow_url" -H "$headers" -d "$sample_data")

# Grab the execution ID from the response
execution_id=$(echo $response | jq -r '.execution_id')

# Check the status of the execution
retrieve_results_url="${api_endpoint}/executions/$execution_id"
result=$(curl -s -X GET "$retrieve_results_url" -H "$headers")

# Print the outputs if the status is completed
status=$(echo $result | jq -r '.status')
if [ "$status" = "completed" ]; then
  outputs=$(echo $result | jq -r '.outputs')
  echo "$outputs"
fi
        `,
    },
    {
      title: 'Python',
      language: 'python',
      content: `
import requests
import json

# Define the URL
execute_workflow_url = '${api_endpoint}'

# Define the headers
headers = {
  'Content-type': 'application/json'
}

# Define the sample JSON body
sample_data = ${JSON.stringify(workflow_inputs_definition, null, 2)}

# Make the POST request
response = requests.post(execute_workflow_url, headers=headers, json=sample_data)

# Grab the execution ID from the response
if response.status_code == 200:
    execution_id = response.json()["execution_id"]
    print(execution_id)

# Check the status of the execution
retrieve_results_url = '${api_endpoint}/executions/{execution_id}'.format(execution_id=execution_id)

response = requests.get(retrieve_results_url, headers=headers)
    
if response.status_code == 200:
    data = response.json()
    if data.get('status') == 'completed':
        outputs = data.get('outputs')
        print(outputs)
    `,
    },
    {
      title: 'Node.js',
      language: 'javascript',
      content: `
const axios = require('axios');

// Define the URL
const executeWorkflowUrl = ${api_endpoint};

// Define the headers
const headers = {
'Content-Type': 'application/json'
};

// Define the sample JSON body
const sampleData = ${JSON.stringify(workflow_inputs_definition, null, 2)};

// Make the POST request
axios.post(executeWorkflowUrl, sampleData, { headers })
.then(response => {
    if (response.status === 200) {
    const executionId = response.data.execution_id;
    console.log(executionId);

    // Check the status of the execution
    const retrieveResultsUrl = \`${api_endpoint}/executions/\${executionId}\`;

    return axios.get(retrieveResultsUrl, { headers });
    } else {
    throw new Error('Failed to execute workflow');
    }
})
.then(response => {
    if (response.status === 200) {
    const data = response.data;
    if (data.status === 'completed') {
        const outputs = data.outputs;
        console.log(outputs);
    } else {
        console.log('Execution not completed yet');
    }
    } else {
    throw new Error('Failed to retrieve execution results');
    }
})
.catch(error => {
    console.error(error);
});
      `,
    },
  ]
}
