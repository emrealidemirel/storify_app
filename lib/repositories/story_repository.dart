import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_story_app/models/story_model.dart';

class StoryRepository {
  final String token = dotenv.env["GPT_TOKEN"] ?? "";

  Future<Story?> startNewStory(
    String storyTheme,
    String gender,
    String languageCode,
  ) async {
    final openAI = OpenAI.instance.build(
      token: token,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
      enableLog: true,
    );

    final prompt =
        languageCode == "en"
            ? """
You are a short interactive story teller. Each story part should be exactly 20 words long. At the end of each part, present 3 short choices (1-3 words).

Create a new unique story. Do not reuse previous parts or repeat the same beginning in multiple story sessions.

Respond ONLY with a valid JSON in this format:

{
  "text": "short story part goes here",
  "choices": ["choice 1", "choice 2", "choice 3"]
}

Theme: $storyTheme
Character: $gender
"""
            : """
Sen kısa bölümlerle interaktif bir hikaye anlatıcısısın. Hikaye her seferinde yalnızca 20 kelime uzunluğunda olmalı. Her bölüm sonunda kullanıcıya 3 kısa seçenek sunmalısın (1-3 kelime arası).

Yeni ve benzersiz bir hikaye oluştur. Önceki bölümleri veya tekrarları kesinlikle kullanma. Aynı hikayenin başlangıcını birden fazla kez yazma.

Cevabını aşağıdaki formatta, **sadece geçerli bir JSON olarak** döndür:

{
  "text": "kısa hikaye bölümü buraya gelecek",
  "choices": ["seçenek 1", "seçenek 2", "seçenek 3"]
}

Tema: $storyTheme
Karakter: $gender
""";

    final request = ChatCompleteText(
      messages: [
        {"role": "user", "content": prompt},
      ],
      maxToken: 200,
      model: ChatModelFromValue(model: 'gpt-3.5-turbo'),
    );

    final response = await openAI.onChatCompletion(request: request);
    if (response?.choices.first.message?.content != null) {
      return storyFromJson(response!.choices.first.message!.content);
    }
    return null;
  }

  Future<Story?> continueStory(
    String lastStory,
    String choice,
    String storyTheme,
    String gender,
    String languageCode,
  ) async {
    final openAI = OpenAI.instance.build(
      token: token,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
      enableLog: true,
    );

    final prompt =
        languageCode == "en"
            ? """
Continue the following story based on the given choice. The continuation should be maximum 20 words. Always provide 3 new short choices (1-3 words).

Avoid repetition. Do not reuse previous story parts or choices.

Respond ONLY with valid JSON:

{
  "text": "story continuation",
  "choices": ["choice 1", "choice 2", "choice 3"]
}

Theme: $storyTheme
Character: $gender

Story: $lastStory  
Choice: $choice
"""
            : """
Şu hikayeyi verilen seçime göre devam ettir. Devam kısmı maksimum 20 kelime olsun. Her zaman 3 yeni kısa seçenek ver (1-3 kelime arası).

Hikaye boyunca kendini tekrar etme. Önceki bölümlerde geçen metni veya seçenekleri kullanma.

Lütfen cevabını geçerli bir JSON formatında döndür:

{
  "text": "hikaye devamı",
  "choices": ["seçenek 1", "seçenek 2", "seçenek 3"]
}

Tema: $storyTheme
Karakter: $gender

Hikaye: $lastStory  
Seçim: $choice
""";

    final request = ChatCompleteText(
      messages: [
        {"role": "user", "content": prompt},
      ],
      maxToken: 200,
      model: ChatModelFromValue(model: 'gpt-3.5-turbo'),
    );

    final response = await openAI.onChatCompletion(request: request);
    if (response?.choices.first.message?.content != null) {
      return storyFromJson(response!.choices.first.message!.content);
    }
    return null;
  }
}
