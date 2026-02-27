import '../models/chat_message.dart';
import '../models/citation.dart';
import '../models/message_role.dart';

final List<ChatMessage> mockMessages = [
  ChatMessage(
    id: 'm1',
    role: MessageRole.user,
    content: 'Can you explain Ayat al-Kursi and its significance?',
    timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
  ),
  ChatMessage(
    id: 'm2',
    role: MessageRole.assistant,
    content:
        'Ayat al-Kursi (The Throne Verse) is verse 255 of Surah Al-Baqarah. '
        'It is one of the most well-known and frequently recited verses of the Quran. '
        'The Prophet Muhammad (PBUH) described it as the greatest verse in the Quran.\n\n'
        'This verse speaks about the absolute oneness of Allah, His eternal nature, '
        'and His supreme authority over all creation. It is commonly recited for '
        'protection and blessings.',
    citations: [
      const Citation(
        source: 'Quran 2:255',
        arabicText:
            'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ '
            'لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ '
            'لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ',
        translation:
            'Allah - there is no deity except Him, the Ever-Living, '
            'the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. '
            'To Him belongs whatever is in the heavens and whatever is on the earth.',
        explanation:
            'This verse establishes the absolute oneness (Tawhid) and sovereignty '
            'of Allah. It describes His attributes of eternal life (Al-Hayy) and '
            'self-sustenance (Al-Qayyum), emphasizing that He is beyond any human limitation.',
        reference: 'Surah Al-Baqarah, Verse 255',
      ),
    ],
    timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
  ),
  ChatMessage(
    id: 'm3',
    role: MessageRole.user,
    content: 'What did the Prophet (PBUH) say about its importance?',
    timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
  ChatMessage(
    id: 'm4',
    role: MessageRole.assistant,
    content:
        'The Prophet Muhammad (PBUH) highlighted the significance of Ayat al-Kursi '
        'in multiple authentic narrations. He affirmed it as the greatest verse '
        'in the Book of Allah and mentioned its protective qualities.',
    citations: [
      const Citation(
        source: 'Sahih Muslim 810',
        arabicText: 'أَعْظَمُ آيَةٍ فِي كِتَابِ اللَّهِ آيَةُ الْكُرْسِيِّ',
        translation:
            'The greatest verse in the Book of Allah is Ayat al-Kursi.',
        explanation:
            'Ubayy ibn Ka\'b reported that the Prophet (PBUH) asked him which verse '
            'in the Book of Allah was the greatest. When Ubayy answered Ayat al-Kursi, '
            'the Prophet struck him on the chest and said: "May knowledge rejoice you, '
            'O Abu al-Mundhir!"',
        reference: 'Sahih Muslim, Book of Prayer, Hadith 810',
      ),
      const Citation(
        source: 'Sahih al-Bukhari 5010',
        arabicText:
            'إِذَا أَوَيْتَ إِلَى فِرَاشِكَ فَاقْرَأْ آيَةَ الْكُرْسِيِّ',
        translation:
            'When you go to your bed, recite Ayat al-Kursi.',
        explanation:
            'Abu Hurairah narrated that the Prophet (PBUH) taught that reciting '
            'Ayat al-Kursi before sleeping provides divine protection throughout '
            'the night, and no devil shall come near until morning.',
        reference: 'Sahih al-Bukhari, Book of Virtues of the Quran, Hadith 5010',
      ),
    ],
    timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
  ),
];

// A mock response used when simulating AI replies
ChatMessage getMockAiResponse() => ChatMessage(
  id: 'mock-response-${DateTime.now().millisecondsSinceEpoch}',
  role: MessageRole.assistant,
  content:
      'Based on the Islamic sources, here is what I found regarding your question:\n\n'
      'Islam places great emphasis on this matter, and there are clear guidelines '
      'from both the Quran and authentic Hadith collections.',
  citations: const [
    Citation(
      source: 'Quran 49:13',
      arabicText:
          'يَا أَيُّهَا النَّاسُ إِنَّا خَلَقْنَاكُم مِّن ذَكَرٍ وَأُنثَىٰ '
          'وَجَعَلْنَاكُمْ شُعُوبًا وَقَبَائِلَ لِتَعَارَفُوا',
      translation:
          'O mankind, indeed We have created you from male and female and made '
          'you peoples and tribes that you may know one another.',
      explanation:
          'This verse emphasizes the unity of humanity and the purpose of '
          'diversity in Islam — to foster mutual understanding and respect.',
      reference: 'Surah Al-Hujurat, Verse 13',
    ),
  ],
  timestamp: DateTime.now(),
);
