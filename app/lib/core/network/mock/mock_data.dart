/// Demo content. TakaPay is a made-up brand used only for practice.
abstract final class MockData {
  static const lessons = <Map<String, dynamic>>[
    {
      'id': 'l1',
      'sender': '01712345678',
      'body': 'TakaPay: Congratulations! You won Tk 5,000 cashback. Send your PIN to claim it today.',
      'isScam': true,
      'signsEn': ['Real services never ask for your PIN.', 'An unexpected prize is bait.', 'It came from a personal number, not TakaPay.'],
      'signsBn': ['আসল প্রতিষ্ঠান কখনো পিন চায় না।', 'অপ্রত্যাশিত পুরস্কার একটি ফাঁদ।', 'এটি TakaPay থেকে নয়, ব্যক্তিগত নম্বর থেকে এসেছে।'],
    },
    {
      'id': 'l2',
      'sender': 'TakaPay',
      'body': 'You have received Tk 500 from 01XXXXXXX45. Balance: Tk 1,240. TrxID 9KD82HS1.',
      'isScam': false,
      'signsEn': ['It comes from the official sender name.', 'It does not ask you to do anything.', 'You can confirm the balance in the official app.'],
      'signsBn': ['এটি অফিসিয়াল প্রেরকের নাম থেকে এসেছে।', 'এটি আপনাকে কিছু করতে বলছে না।', 'অফিসিয়াল অ্যাপে ব্যালেন্স মিলিয়ে দেখতে পারেন।'],
    },
    {
      'id': 'l3',
      'sender': '01812345678',
      'body': 'আপনার TakaPay অ্যাকাউন্ট আজই ব্লক হবে। এখনই যাচাই করুন: takapay-verify.xyz',
      'isScam': true,
      'signsEn': ['It threatens to block your account today.', 'The link is not the official website.', 'It came from a personal number.'],
      'signsBn': ['আজই অ্যাকাউন্ট ব্লকের ভয় দেখাচ্ছে।', 'লিংকটি অফিসিয়াল ওয়েবসাইট নয়।', 'এটি ব্যক্তিগত নম্বর থেকে এসেছে।'],
    },
    {
      'id': 'l4',
      'sender': 'TakaPay',
      'body': 'Your verification code is 482913. Do not share this code with anyone, including TakaPay staff.',
      'isScam': false,
      'signsEn': ['It arrived right after you tried to log in yourself.', 'It tells you not to share the code.', 'Never read this code out to a caller.'],
      'signsBn': ['আপনি নিজে লগইন করার পরই এটি এসেছে।', 'এটি কোড শেয়ার না করতে বলছে।', 'ফোনে কাউকে এই কোড বলবেন না।'],
    },
    {
      'id': 'l5',
      'sender': '01912345678',
      'body': 'Part-time job! Earn Tk 3,000 a day from home. Send Tk 500 registration fee to this number to start.',
      'isScam': true,
      'signsEn': ['Big money for little work is a common trap.', 'Real employers rarely ask for money to hire you.', 'Money sent to a personal number is hard to get back.'],
      'signsBn': ['কম কাজে বেশি টাকার প্রস্তাব একটি সাধারণ ফাঁদ।', 'আসল নিয়োগকর্তা সাধারণত চাকরি দিতে টাকা চায় না।', 'ব্যক্তিগত নম্বরে পাঠানো টাকা ফেরত পাওয়া কঠিন।'],
    },
  ];

  // Verify every number on the provider's official website before launch.
  static const helplines = <Map<String, dynamic>>[
    {'id': 'bkash', 'nameEn': 'bKash', 'nameBn': 'বিকাশ', 'number': '16247'},
    {'id': 'nagad', 'nameEn': 'Nagad', 'nameBn': 'নগদ', 'number': '16167'},
    {'id': 'rocket', 'nameEn': 'Rocket (Dutch-Bangla Bank)', 'nameBn': 'রকেট (ডাচ্-বাংলা ব্যাংক)', 'number': '16216'},
    {'id': 'emergency', 'nameEn': 'National emergency service', 'nameBn': 'জাতীয় জরুরি সেবা', 'number': '999'},
  ];

  static Map<String, dynamic> guardian() => <String, dynamic>{
        'paired': true,
        'name': 'Ammu',
        'lastAlertAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      };
}