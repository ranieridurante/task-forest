import React, { useMemo, useState } from 'react'
import SyntaxHighlighter from 'react-syntax-highlighter/dist/esm/prism'
import { solarizedlight } from 'react-syntax-highlighter/dist/esm/styles/prism'
import { CopyToClipboard } from 'react-copy-to-clipboard'
import type { TWorkflow } from 'types/workflow'
import type { TIODefinitions } from 'types/task'
import type { TWorkflowAPIEndpointDocsCodeBlock, TProgrammingLanguage } from 'types/docs'

/**
 * Returns a map of inputs with their example value.
 * @param inputs_definition Input definition map.
 */
const getSampleData = (inputs_definition: TIODefinitions) =>
  Object.entries(inputs_definition).reduce(
    (acc: { [key: string]: string }, [key, { type }]) => {
      const typeToShow = type == 'text' ? 'string' : type
      acc[key] = 'a valid ' + typeToShow
      return acc
    },
    {}
  )

/**
 * Returns the documentation for the Workflow API Endpoint in the specified programming language.
 */
const getCodeForLanguage = (
  { api_endpoint, inputs_definition }: TWorkflow,
  language: TProgrammingLanguage,
  company_auth_token: string
) => {
  const sample_data = getSampleData(inputs_definition)

  switch (language) {
    case 'bash':
      return `# Define the URL and headers
    execute_workflow_url='${api_endpoint}'
    headers='Content-Type: application/json'
    auth_header='Authorization: Bearer ${company_auth_token}'

    # Define the sample JSON body
    sample_data='${JSON.stringify(getSampleData(inputs_definition), null, 2)}'

    # Make the POST request
    response=$(curl -s -X POST "$execute_workflow_url" -H "$headers" -H "$auth_header" -d "$sample_data")

    # Grab the execution ID from the response
    execution_id=$(echo $response | jq -r '.execution_id')

    # Check the status of the execution
    retrieve_results_url="${api_endpoint}/executions/$execution_id"
    result=$(curl -s -X GET "$retrieve_results_url" -H "$headers" -H "$auth_header")

    # Print the outputs if the status is completed
    status=$(echo $result | jq -r '.status')
    if [ "$status" = "completed" ]; then
      outputs=$(echo $result | jq -r '.outputs')
      echo "$outputs"
    fi`
    case 'python':
      return `import requests
    import json

    # Define the URL
    execute_workflow_url = '${api_endpoint}'

    # Define the headers
    headers = {
        'Content-type': 'application/json',
        'Authorization': 'Bearer ${company_auth_token}'
    }

    # Define the sample JSON body
    sample_data = ${JSON.stringify(getSampleData(inputs_definition), null, 2)}

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
        print(outputs)`
    case 'javascript':
      return `const axios = require('axios');

    // Define the URL
    const executeWorkflowUrl = ${api_endpoint};

    // Define the headers
    const headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${company_auth_token}'
    };

    // Define the sample JSON body
    const sampleData = ${JSON.stringify(
      getSampleData(inputs_definition),
      null,
      2
    )};

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
    });`
    case 'java':
      return `import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.URI;
import org.json.JSONObject;

public class WorkflowClient {
    public static void main(String[] args) {
        HttpClient client = HttpClient.newHttpClient();
        JSONObject data = new JSONObject();
        ${Object.entries(sample_data)
          .map(([key, value]) => `data.put("${key}", "${value}");`)
          .join('\n        ')}

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create("${api_endpoint}"))
            .header("Content-Type", "application/json")
            .header("Authorization", "Bearer ${company_auth_token}")
            .POST(HttpRequest.BodyPublishers.ofString(data.toString()))
            .build();

        try {
            HttpResponse<String> response = client.send(request, 
                HttpResponse.BodyHandlers.ofString());
            System.out.println(response.body());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}`

    case 'spring':
      return `import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpEntity;
import org.springframework.http.MediaType;
import org.springframework.web.client.RestTemplate;
import java.util.HashMap;
import java.util.Map;

@Service
public class WorkflowService {
    private final RestTemplate restTemplate = new RestTemplate();

    public void executeWorkflow() {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth("${company_auth_token}");

        Map<String, Object> data = new HashMap<>();
        ${Object.entries(sample_data)
          .map(([key, value]) => `data.put("${key}", "${value}");`)
          .join('\n        ')}

        HttpEntity<Map<String, Object>> request = 
            new HttpEntity<>(data, headers);

        String response = restTemplate.postForObject(
            "${api_endpoint}",
            request,
            String.class
        );
        System.out.println(response);
    }
}`

    case 'elixir':
      return `defmodule WorkflowClient do
  def execute_workflow do
    url = "${api_endpoint}"
    headers = [
      {"Authorization", "Bearer ${company_auth_token}"},
      {"Content-Type", "application/json"}
    ]
    
    payload = %{
      ${Object.entries(sample_data)
        .map(([key, value]) => `"${key}" => "${value}"`)
        .join(',\n      ')}
    }

    case HTTPoison.post(url, Jason.encode!(payload), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}
      {:error, error} ->
        {:error, error}
    end
  end
end`
  }
}

/**
 * Component that represents a code box for documenting the use of a Workflow API Endpoint.
 * @constructor
 */
const WorkflowAPIEndpointDocsCodeBlock: React.FC<
  TWorkflowAPIEndpointDocsCodeBlock
> = ({ workflow, language, company_auth_token }) => {
  const [copied, setCopied] = useState(false)

  const code = useMemo(
    () => getCodeForLanguage(workflow, language, company_auth_token),
    [workflow]
  )

  return (
    <>
      <SyntaxHighlighter
        language={language}
        style={solarizedlight}
        wrapLongLines
        showInlineLineNumbers={true}
      >
        {code}
      </SyntaxHighlighter>
      <CopyToClipboard text={code} onCopy={() => setCopied(true)}>
        <button className='absolute top-2 right-2 bg-primary-500 text-white px-2 py-1 rounded-md'>
          {copied ? 'Copied!' : 'Copy'}
        </button>
      </CopyToClipboard>
    </>
  )
}

export default WorkflowAPIEndpointDocsCodeBlock
