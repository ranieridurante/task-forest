defmodule TaskForest.Models.PlombAi do
  @behaviour TaskForest.Models.ModelProvider

  alias TaskForest.Models.GenericChatCompletion

  require Logger

  @selection_model "meta-llama/llama-4-scout:free"

  @impl true
  def call(_model_id, model_params, %{"loaded_prompt" => loaded_prompt} = _input_params, _provider_keys, task_info) do
    with provider_keys <- get_provider_keys(),
         {:ok, model} <- select_model(loaded_prompt, provider_keys, task_info, model_params),
         {:ok, response} <- generate_response(loaded_prompt, model, provider_keys, task_info, model_params) do
      {:ok, response}
    else
      {:error, reason} ->
        Logger.error("PlombAI Error: #{inspect(reason)}")

        {:error, "PlombAI processing failed: #{inspect(reason)}"}
    end
  end

  defp select_model(loaded_prompt, provider_keys, task_info, model_params) do
    model_selection_prompt = build_model_selection_prompt(loaded_prompt)

    case request_model_selection(model_selection_prompt, provider_keys, task_info, model_params) do
      {:ok, %{"chosen_model" => model}} ->
        model =
          if not String.ends_with?(model, ":free") do
            model <> ":free"
          else
            model
          end

        Logger.info("PlombAi: Selected model #{model} for task #{task_info.name}")

        {:ok, model}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp generate_response(prompt, model, provider_keys, task_info, model_params) do
    GenericChatCompletion.call(
      model,
      model_params,
      %{"loaded_prompt" => prompt},
      provider_keys,
      task_info
    )
  end

  defp request_model_selection(prompt, provider_keys, task_info, model_params) do
    GenericChatCompletion.call(
      @selection_model,
      model_params,
      %{"loaded_prompt" => prompt},
      provider_keys,
      task_info
    )
  end

  defp build_model_selection_prompt(user_prompt) do
    """
    Given the following list of models (delimited by <models></models>) with their characteristics, choose the best model for the provided user prompt (delimited by <user_prompt></user_prompt>):
    <models>
    1. model_id: cognitivecomputations/dolphin3.0-r1-mistral-24b:free
      languages: English, French, Spanish, Italian and German
      capabilities: translation, creative writing, summarization, question answering, chat, roleplaying
      context_window: 32,768 tokens
      price: free
    2. model_id: cognitivecomputations/dolphin3.0-mistral-24b:free
      languages: English, French, Spanish, Italian and German
      capabilities: translation, creative writing, summarization, question answering, chat, roleplaying
      context_window: 32,768 tokens
      price: free
    3. model_id: google/gemini-2.0-pro-exp-02-05:free
      languages: Arabic (ar), Bengali (bn), Bulgarian (bg), Chinese simplified and traditional (zh), Croatian (hr), Czech (cs), Danish (da), Dutch (nl), English (en), Estonian (et), Finnish (fi), French (fr), German (de), Greek (el), Hebrew (iw), Hindi (hi), Hungarian (hu), Indonesian (id), Italian (it), Japanese (ja), Korean (ko), Latvian (lv), Lithuanian (lt), Norwegian (no), Polish (pl), Portuguese (pt), Romanian (ro), Russian (ru), Serbian (sr), Slovak (sk), Slovenian (sl), Spanish (es), Swahili (sw), Swedish (sv), Thai (th), Turkish (tr), Ukrainian (uk), Vietnamese (vi), Afrikaans (af), Amharic (am), Assamese (as), Azerbaijani (az), Belarusian (be), Bosnian (bs), Catalan (ca), Cebuano (ceb), Corsican (co), Welsh (cy), Dhivehi (dv), Esperanto (eo), Basque (eu), Persian (fa), Filipino (Tagalog) (fil), Frisian (fy), Irish (ga), Scots Gaelic (gd), Galician (gl), Gujarati (gu), Hausa (ha), Hawaiian (haw), Hmong (hmn), Haitian Creole (ht), Armenian (hy), Igbo (ig), Icelandic (is), Javanese (jv), Georgian (ka), Kazakh (kk), Khmer (km), Kannada (kn), Krio (kri), Kurdish (ku), Kyrgyz (ky), Latin (la), Luxembourgish (lb), Lao (lo), Malagasy (mg), Maori (mi), Macedonian (mk), Malayalam (ml), Mongolian (mn), Meiteilon (Manipuri) (mni-Mtei), Marathi (mr), Malay (ms), Maltese (mt), Myanmar (Burmese) (my), Nepali (ne), Nyanja (Chichewa) (ny), Odia (Oriya) (or), Punjabi (pa), Pashto (ps), Sindhi (sd), Sinhala (Sinhalese) (si), Samoan (sm), Shona (sn), Somali (so), Albanian (sq), Sesotho (st), Sundanese (su), Tamil (ta), Telugu (te), Tajik (tg), Uyghur (ug), Urdu (ur), Uzbek (uz), Xhosa (xh), Yiddish (yi), Yoruba (yo), Zulu (zu)
      capabilities: translation, creative writing, content generation, summarization, programming, general knowledge, reasoning
      context_window: 2,000,000 tokens
      price: free
    4. model_id: mistralai/mistral-small-24b-instruct-2501:free
      languages:
      capabilities:
      context_window: 32,000 tokens
      price: free
    5. model_id: deepseek/deepseek-r1-distill-llama-70b:free
      languages: English, Spanish, French, German, Chinese (Simplified), Chinese (Traditional), Japanese, Korean, Italian, Portuguese, Russian, Arabic, Hindi, Dutch, Turkish, Polish, Swedish, Finnish, Danish, Norwegian, Greek, Czech, Hungarian, Romanian, Thai, Vietnamese, Indonesian, Malay, Filipino (Tagalog), Ukrainian, Catalan, Bulgarian, Croatian, Serbian, Slovak, Slovenian, Hebrew, Persian (Farsi), Urdu, Bengali, Tamil, Telugu, Gujarati, Punjabi, Marathi, Kannada, Malayalam, Swahili, Zulu, Afrikaans, Icelandic, Irish, Welsh, Basque, Galician, Estonian, Latvian, Lithuanian, Albanian, Macedonian, Armenian, Georgian, Azerbaijani, Uzbek, Kazakh, Kyrgyz, Tajik, Turkmen, Mongolian, Nepali, Sinhala, Burmese, Khmer, Lao, Haitian Creole, Maori, Samoan, Tongan, Fijian, Maltese, Luxembourgish, Faroese, Quechua, Aymara, Nahuatl, Guarani, Cherokee, Inuktitut, Hawaiian, Māori, Sardinian, Corsican, Mapudungun, Kichwa, Yucatec Maya, K'iche', Ojibwe, Cree, Navajo, Hopi, Mohawk, Greenlandic, Northern Sami, Southern Sami, Breton, Cornish, Manx, Scottish Gaelic, Romansh, Ladin, Friulian, Occitan, Provençal, Sicilian, Neapolitan, Venetian, Lombard, Piedmontese
      capabilities: programming, math reasoning, reasoning, translation, creative writing, content generation, chat, roleplaying
      capabilities:
      context_window: 128,000 tokens
      price: free
    6. model_id: google/gemini-2.0-flash-thinking-exp:free
      languages: Arabic (ar), Bengali (bn), Bulgarian (bg), Chinese simplified and traditional (zh), Croatian (hr), Czech (cs), Danish (da), Dutch (nl), English (en), Estonian (et), Finnish (fi), French (fr), German (de), Greek (el), Hebrew (iw), Hindi (hi), Hungarian (hu), Indonesian (id), Italian (it), Japanese (ja), Korean (ko), Latvian (lv), Lithuanian (lt), Norwegian (no), Polish (pl), Portuguese (pt), Romanian (ro), Russian (ru), Serbian (sr), Slovak (sk), Slovenian (sl), Spanish (es), Swahili (sw), Swedish (sv), Thai (th), Turkish (tr), Ukrainian (uk), Vietnamese (vi), Afrikaans (af), Amharic (am), Assamese (as), Azerbaijani (az), Belarusian (be), Bosnian (bs), Catalan (ca), Cebuano (ceb), Corsican (co), Welsh (cy), Dhivehi (dv), Esperanto (eo), Basque (eu), Persian (fa), Filipino (Tagalog) (fil), Frisian (fy), Irish (ga), Scots Gaelic (gd), Galician (gl), Gujarati (gu), Hausa (ha), Hawaiian (haw), Hmong (hmn), Haitian Creole (ht), Armenian (hy), Igbo (ig), Icelandic (is), Javanese (jv), Georgian (ka), Kazakh (kk), Khmer (km), Kannada (kn), Krio (kri), Kurdish (ku), Kyrgyz (ky), Latin (la), Luxembourgish (lb), Lao (lo), Malagasy (mg), Maori (mi), Macedonian (mk), Malayalam (ml), Mongolian (mn), Meiteilon (Manipuri) (mni-Mtei), Marathi (mr), Malay (ms), Maltese (mt), Myanmar (Burmese) (my), Nepali (ne), Nyanja (Chichewa) (ny), Odia (Oriya) (or), Punjabi (pa), Pashto (ps), Sindhi (sd), Sinhala (Sinhalese) (si), Samoan (sm), Shona (sn), Somali (so), Albanian (sq), Sesotho (st), Sundanese (su), Tamil (ta), Telugu (te), Tajik (tg), Uyghur (ug), Urdu (ur), Uzbek (uz), Xhosa (xh), Yiddish (yi), Yoruba (yo), Zulu (zu)
      capabilities: translation, creative writing, content generation, summarization, programming, general knowledge, reasoning
      context_window: 1,048,576 tokens
      price: free
    7. model_id: deepseek/deepseek-r1:free
      languages: English, Spanish, French, German, Chinese (Simplified), Chinese (Traditional), Japanese, Korean, Italian, Portuguese, Russian, Arabic, Hindi, Dutch, Turkish, Polish, Swedish, Finnish, Danish, Norwegian, Greek, Czech, Hungarian, Romanian, Thai, Vietnamese, Indonesian, Malay, Filipino (Tagalog), Ukrainian, Catalan, Bulgarian, Croatian, Serbian, Slovak, Slovenian, Hebrew, Persian (Farsi), Urdu, Bengali, Tamil, Telugu, Gujarati, Punjabi, Marathi, Kannada, Malayalam, Swahili, Zulu, Afrikaans, Icelandic, Irish, Welsh, Basque, Galician, Estonian, Latvian, Lithuanian, Albanian, Macedonian, Armenian, Georgian, Azerbaijani, Uzbek, Kazakh, Kyrgyz, Tajik, Turkmen, Mongolian, Nepali, Sinhala, Burmese, Khmer, Lao, Haitian Creole, Maori, Samoan, Tongan, Fijian, Maltese, Luxembourgish, Faroese, Quechua, Aymara, Nahuatl, Guarani, Cherokee, Inuktitut, Hawaiian, Māori, Sardinian, Corsican, Mapudungun, Kichwa, Yucatec Maya, K'iche', Ojibwe, Cree, Navajo, Hopi, Mohawk, Greenlandic, Northern Sami, Southern Sami, Breton, Cornish, Manx, Scottish Gaelic, Romansh, Ladin, Friulian, Occitan, Provençal, Sicilian, Neapolitan, Venetian, Lombard, Piedmontese
      capabilities: programming, math reasoning, reasoning, translation, creative writing, content generation, chat, roleplaying
      context_window: 163,840 tokens
      price: free
    8. model_id: sophosympatheia/rogue-rose-103b-v0.2:free
      languages: English
      capabilities: roleplaying, chat, creative writing
      context_window: 4,096 tokens
      price: free
    9. model_id: deepseek/deepseek-chat:free
      languages: English, Spanish, French, German, Chinese (Simplified), Chinese (Traditional), Japanese, Korean, Italian, Portuguese, Russian, Arabic, Hindi, Dutch, Turkish, Polish, Swedish, Finnish, Danish, Norwegian, Greek, Czech, Hungarian, Romanian, Thai, Vietnamese, Indonesian, Malay, Filipino (Tagalog), Ukrainian, Catalan, Bulgarian, Croatian, Serbian, Slovak, Slovenian, Hebrew, Persian (Farsi), Urdu, Bengali, Tamil, Telugu, Gujarati, Punjabi, Marathi, Kannada, Malayalam, Swahili, Zulu, Afrikaans, Icelandic, Irish, Welsh, Basque, Galician, Estonian, Latvian, Lithuanian, Albanian, Macedonian, Armenian, Georgian, Azerbaijani, Uzbek, Kazakh, Kyrgyz, Tajik, Turkmen, Mongolian, Nepali, Sinhala, Burmese, Khmer, Lao, Haitian Creole, Maori, Samoan, Tongan, Fijian, Maltese, Luxembourgish, Faroese, Quechua, Aymara, Nahuatl, Guarani, Cherokee, Inuktitut, Hawaiian, Māori, Sardinian, Corsican, Mapudungun, Kichwa, Yucatec Maya, K'iche', Ojibwe, Cree, Navajo, Hopi, Mohawk, Greenlandic, Northern Sami, Southern Sami, Breton, Cornish, Manx, Scottish Gaelic, Romansh, Ladin, Friulian, Occitan, Provençal, Sicilian, Neapolitan, Venetian, Lombard, Piedmontese
      capabilities: programming, math reasoning, reasoning, translation, creative writing, content generation, chat, roleplaying
      context_window: 131,072 tokens
      price: free
    10. model_id: google/gemini-2.0-flash-thinking-exp-1219:free
      languages: Arabic (ar), Bengali (bn), Bulgarian (bg), Chinese simplified and traditional (zh), Croatian (hr), Czech (cs), Danish (da), Dutch (nl), English (en), Estonian (et), Finnish (fi), French (fr), German (de), Greek (el), Hebrew (iw), Hindi (hi), Hungarian (hu), Indonesian (id), Italian (it), Japanese (ja), Korean (ko), Latvian (lv), Lithuanian (lt), Norwegian (no), Polish (pl), Portuguese (pt), Romanian (ro), Russian (ru), Serbian (sr), Slovak (sk), Slovenian (sl), Spanish (es), Swahili (sw), Swedish (sv), Thai (th), Turkish (tr), Ukrainian (uk), Vietnamese (vi), Afrikaans (af), Amharic (am), Assamese (as), Azerbaijani (az), Belarusian (be), Bosnian (bs), Catalan (ca), Cebuano (ceb), Corsican (co), Welsh (cy), Dhivehi (dv), Esperanto (eo), Basque (eu), Persian (fa), Filipino (Tagalog) (fil), Frisian (fy), Irish (ga), Scots Gaelic (gd), Galician (gl), Gujarati (gu), Hausa (ha), Hawaiian (haw), Hmong (hmn), Haitian Creole (ht), Armenian (hy), Igbo (ig), Icelandic (is), Javanese (jv), Georgian (ka), Kazakh (kk), Khmer (km), Kannada (kn), Krio (kri), Kurdish (ku), Kyrgyz (ky), Latin (la), Luxembourgish (lb), Lao (lo), Malagasy (mg), Maori (mi), Macedonian (mk), Malayalam (ml), Mongolian (mn), Meiteilon (Manipuri) (mni-Mtei), Marathi (mr), Malay (ms), Maltese (mt), Myanmar (Burmese) (my), Nepali (ne), Nyanja (Chichewa) (ny), Odia (Oriya) (or), Punjabi (pa), Pashto (ps), Sindhi (sd), Sinhala (Sinhalese) (si), Samoan (sm), Shona (sn), Somali (so), Albanian (sq), Sesotho (st), Sundanese (su), Tamil (ta), Telugu (te), Tajik (tg), Uyghur (ug), Urdu (ur), Uzbek (uz), Xhosa (xh), Yiddish (yi), Yoruba (yo), Zulu (zu)
      capabilities: translation, creative writing, content generation, summarization, programming, general knowledge, reasoning
      context_window: 40,000 tokens
      price: free
    11. model_id: google/gemini-2.0-flash-exp:free
      languages: Arabic (ar), Bengali (bn), Bulgarian (bg), Chinese simplified and traditional (zh), Croatian (hr), Czech (cs), Danish (da), Dutch (nl), English (en), Estonian (et), Finnish (fi), French (fr), German (de), Greek (el), Hebrew (iw), Hindi (hi), Hungarian (hu), Indonesian (id), Italian (it), Japanese (ja), Korean (ko), Latvian (lv), Lithuanian (lt), Norwegian (no), Polish (pl), Portuguese (pt), Romanian (ro), Russian (ru), Serbian (sr), Slovak (sk), Slovenian (sl), Spanish (es), Swahili (sw), Swedish (sv), Thai (th), Turkish (tr), Ukrainian (uk), Vietnamese (vi), Afrikaans (af), Amharic (am), Assamese (as), Azerbaijani (az), Belarusian (be), Bosnian (bs), Catalan (ca), Cebuano (ceb), Corsican (co), Welsh (cy), Dhivehi (dv), Esperanto (eo), Basque (eu), Persian (fa), Filipino (Tagalog) (fil), Frisian (fy), Irish (ga), Scots Gaelic (gd), Galician (gl), Gujarati (gu), Hausa (ha), Hawaiian (haw), Hmong (hmn), Haitian Creole (ht), Armenian (hy), Igbo (ig), Icelandic (is), Javanese (jv), Georgian (ka), Kazakh (kk), Khmer (km), Kannada (kn), Krio (kri), Kurdish (ku), Kyrgyz (ky), Latin (la), Luxembourgish (lb), Lao (lo), Malagasy (mg), Maori (mi), Macedonian (mk), Malayalam (ml), Mongolian (mn), Meiteilon (Manipuri) (mni-Mtei), Marathi (mr), Malay (ms), Maltese (mt), Myanmar (Burmese) (my), Nepali (ne), Nyanja (Chichewa) (ny), Odia (Oriya) (or), Punjabi (pa), Pashto (ps), Sindhi (sd), Sinhala (Sinhalese) (si), Samoan (sm), Shona (sn), Somali (so), Albanian (sq), Sesotho (st), Sundanese (su), Tamil (ta), Telugu (te), Tajik (tg), Uyghur (ug), Urdu (ur), Uzbek (uz), Xhosa (xh), Yiddish (yi), Yoruba (yo), Zulu (zu)
      capabilities: translation, creative writing, content generation, summarization, programming, general knowledge, reasoning
      context_window: 1,048,576 tokens
      price: free
    12. model_id: google/gemini-exp-1206:free
      languages: Arabic (ar), Bengali (bn), Bulgarian (bg), Chinese simplified and traditional (zh), Croatian (hr), Czech (cs), Danish (da), Dutch (nl), English (en), Estonian (et), Finnish (fi), French (fr), German (de), Greek (el), Hebrew (iw), Hindi (hi), Hungarian (hu), Indonesian (id), Italian (it), Japanese (ja), Korean (ko), Latvian (lv), Lithuanian (lt), Norwegian (no), Polish (pl), Portuguese (pt), Romanian (ro), Russian (ru), Serbian (sr), Slovak (sk), Slovenian (sl), Spanish (es), Swahili (sw), Swedish (sv), Thai (th), Turkish (tr), Ukrainian (uk), Vietnamese (vi)
      capabilities: translation, creative writing, content generation, summarization, programming, general knowledge, reasoning
      context_window: 2,097,152 tokens
      price: free
    13. model_id: meta-llama/llama-3.3-70b-instruct:free
      languages: English, German, French, Italian, Portuguese, Hindi, Spanish, and Thai
      capabilities: translation, creative writing, content generation, summarization, programming, general knowledge, reasoning, mathematical reasoning
      context_window: 131,072 tokens
      price: free
    14. model_id: google/learnlm-1.5-pro-experimental:free
      languages: Arabic (ar), Bengali (bn), Bulgarian (bg), Chinese simplified and traditional (zh), Croatian (hr), Czech (cs), Danish (da), Dutch (nl), English (en), Estonian (et), Finnish (fi), French (fr), German (de), Greek (el), Hebrew (iw), Hindi (hi), Hungarian (hu), Indonesian (id), Italian (it), Japanese (ja), Korean (ko), Latvian (lv), Lithuanian (lt), Norwegian (no), Polish (pl), Portuguese (pt), Romanian (ro), Russian (ru), Serbian (sr), Slovak (sk), Slovenian (sl), Spanish (es), Swahili (sw), Swedish (sv), Thai (th), Turkish (tr), Ukrainian (uk), Vietnamese (vi), Afrikaans (af), Amharic (am), Assamese (as), Azerbaijani (az), Belarusian (be), Bosnian (bs), Catalan (ca), Cebuano (ceb), Corsican (co), Welsh (cy), Dhivehi (dv), Esperanto (eo), Basque (eu), Persian (fa), Filipino (Tagalog) (fil), Frisian (fy), Irish (ga), Scots Gaelic (gd), Galician (gl), Gujarati (gu), Hausa (ha), Hawaiian (haw), Hmong (hmn), Haitian Creole (ht), Armenian (hy), Igbo (ig), Icelandic (is), Javanese (jv), Georgian (ka), Kazakh (kk), Khmer (km), Kannada (kn), Krio (kri), Kurdish (ku), Kyrgyz (ky), Latin (la), Luxembourgish (lb), Lao (lo), Malagasy (mg), Maori (mi), Macedonian (mk), Malayalam (ml), Mongolian (mn), Meiteilon (Manipuri) (mni-Mtei), Marathi (mr), Malay (ms), Maltese (mt), Myanmar (Burmese) (my), Nepali (ne), Nyanja (Chichewa) (ny), Odia (Oriya) (or), Punjabi (pa), Pashto (ps), Sindhi (sd), Sinhala (Sinhalese) (si), Samoan (sm), Shona (sn), Somali (so), Albanian (sq), Sesotho (st), Sundanese (su), Tamil (ta), Telugu (te), Tajik (tg), Uyghur (ug), Urdu (ur), Uzbek (uz), Xhosa (xh), Yiddish (yi), Yoruba (yo), Zulu (zu)
      capabilities: translation, creative writing, content generation, summarization, programming, general knowledge, reasoning
      context_window: 40,960 tokens
      price: free
    15. model_id: nvidia/llama-3.1-nemotron-70b-instruct:free
      languages: English, German, French, Italian, Portuguese, Hindi, Spanish, and Thai
      capabilities: translation, creative writing, content generation, summarization, programming, general knowledge, reasoning
      context_window: 131,072 tokens
      price: free
    16. model_id: meta-llama/llama-3.2-1b-instruct:free
      languages: English, German, French, Italian, Portuguese, Hindi, Spanish, and Thai
      capabilities: translation, creative writing, content generation, summarization, programming, general knowledge, reasoning
      context_window: 131,072 tokens
      price: free
    17. model_id: google/gemini-flash-1.5-8b-exp
      languages: Arabic (ar), Bengali (bn), Bulgarian (bg), Chinese simplified and traditional (zh), Croatian (hr), Czech (cs), Danish (da), Dutch (nl), English (en), Estonian (et), Finnish (fi), French (fr), German (de), Greek (el), Hebrew (iw), Hindi (hi), Hungarian (hu), Indonesian (id), Italian (it), Japanese (ja), Korean (ko), Latvian (lv), Lithuanian (lt), Norwegian (no), Polish (pl), Portuguese (pt), Romanian (ro), Russian (ru), Serbian (sr), Slovak (sk), Slovenian (sl), Spanish (es), Swahili (sw), Swedish (sv), Thai (th), Turkish (tr), Ukrainian (uk), Vietnamese (vi), Afrikaans (af), Amharic (am), Assamese (as), Azerbaijani (az), Belarusian (be), Bosnian (bs), Catalan (ca), Cebuano (ceb), Corsican (co), Welsh (cy), Dhivehi (dv), Esperanto (eo), Basque (eu), Persian (fa), Filipino (Tagalog) (fil), Frisian (fy), Irish (ga), Scots Gaelic (gd), Galician (gl), Gujarati (gu), Hausa (ha), Hawaiian (haw), Hmong (hmn), Haitian Creole (ht), Armenian (hy), Igbo (ig), Icelandic (is), Javanese (jv), Georgian (ka), Kazakh (kk), Khmer (km), Kannada (kn), Krio (kri), Kurdish (ku), Kyrgyz (ky), Latin (la), Luxembourgish (lb), Lao (lo), Malagasy (mg), Maori (mi), Macedonian (mk), Malayalam (ml), Mongolian (mn), Meiteilon (Manipuri) (mni-Mtei), Marathi (mr), Malay (ms), Maltese (mt), Myanmar (Burmese) (my), Nepali (ne), Nyanja (Chichewa) (ny), Odia (Oriya) (or), Punjabi (pa), Pashto (ps), Sindhi (sd), Sinhala (Sinhalese) (si), Samoan (sm), Shona (sn), Somali (so), Albanian (sq), Sesotho (st), Sundanese (su), Tamil (ta), Telugu (te), Tajik (tg), Uyghur (ug), Urdu (ur), Uzbek (uz), Xhosa (xh), Yiddish (yi), Yoruba (yo), Zulu (zu)
      capabilities: translation, creative writing, content generation, summarization, programming, general knowledge, reasoning
      context_window: 1,000,000 tokens
      price: free
    18. model_id: meta-llama/llama-3.1-8b-instruct:free
      languages: English, German, French, Italian, Portuguese, Hindi, Spanish, and Thai
      capabilities: translation, creative writing, content generation, summarization, programming, general knowledge, reasoning
      context_window: 131,072 tokens
      price: free
    19. model_id: mistralai/mistral-nemo:free
      languages: English, French, German, Spanish, Italian, Portuguese, Chinese, Japanese, Korean, Arabic, and Hindi
      capabilities: reasoning, general knowledge, programming, creative writing, content generation, sentiment analysis, translation, summarization
      context_window: 128,000 tokens
      price: free
    20. model_id: google/gemma-2-9b-it:free
      languages: Arabic (ar), Bengali (bn), Bulgarian (bg), Chinese simplified and traditional (zh), Croatian (hr), Czech (cs), Danish (da), Dutch (nl), English (en), Estonian (et), Finnish (fi), French (fr), German (de), Greek (el), Hebrew (iw), Hindi (hi), Hungarian (hu), Indonesian (id), Italian (it), Japanese (ja), Korean (ko), Latvian (lv), Lithuanian (lt), Norwegian (no), Polish (pl), Portuguese (pt), Romanian (ro), Russian (ru), Serbian (sr), Slovak (sk), Slovenian (sl), Spanish (es), Swahili (sw), Swedish (sv), Thai (th), Turkish (tr), Ukrainian (uk), Vietnamese (vi)
      capabilities: creative writing, chat, translation, question answering, summarization, roleplaying, programming
      context_window: 8,192 tokens
      price: free
    21. model_id: mistralai/mistral-7b-instruct:free
      languages: English
      capabilities: programming, general knowledge, question answering,
      context_window: 8,192 tokens
      price: free
    22. model_id: microsoft/phi-3-mini-128k-instruct:free
      languages: English
      capabilities: reasoning, programming, mathematical reasoning, general knowledge
      context_window: 8,192 tokens
      price: free
    23. model_id: microsoft/phi-3-medium-128k-instruct:free
      languages: English
      capabilities: reasoning, programming, mathematical reasoning, general knowledge
      context_window: 8,192 tokens
      price: free
    24. model_id: meta-llama/llama-3-8b-instruct:free
      languages: English, German, French, Italian, Portuguese, Hindi, Spanish, and Thai
      capabilities: translation, creative writing, content generation, summarization, programming, general knowledge, reasoning
      context_window: 8,192 tokens
      price: free
    25. model_id: openchat/openchat-7b:free
      languages: English
      capabilities: chat, general knowledge, translation
      context_window: 8,192 tokens
      price: free
    25. model_id: undi95/toppy-m-7b:free
      languages: English, Spanish, French, German, Italian, Portuguese, Dutch, Russian, Chinese, Japanese, Korean
      capabilities: conversational, roleplaying, creative writing, creative writing, programming,
      context_window: 4,096 tokens
      price: free
    26. model_id: huggingfaceh4/zephyr-7b-beta:free
      languages: English, Spanish, French, German, Italian, Portuguese, Dutch, Russian, Chinese, Japanese, Korean
      capabilities: creative writing, translation, summarization, sentiment analysis, storytelling, content generation, customer support, question answering
      context_window: 4,096 tokens
      price: free
    27. model_id: gryphe/mythomax-l2-13b:free
      languages: English
      capabilities: creative writing, professional writing, technical documentation, roleplaying, chat
      context_window: 4,096 tokens
      price: free
    </models>

    <user_prompt>
    #{user_prompt}
    </user_prompt>

    Please return the chosen model ID as a string  with the key "chosen_model". Your entire response should be a single, valid JSON object without any additional text or formatting.
    This is very important: return ONLY the following json:
    %{
      "chosen_model": <chosen model ID as string>
    }
    """
  end

  defp get_provider_keys do
    plain_keys = %{
      "api_key" => Application.get_env(:task_forest, :openrouter_api_key)
    }

    %{keys: plain_keys}
  end
end
