// Chrome-level translation only (nav, page banners, primary buttons, footer)
// — mirrors the same 5 languages as the Flutter app, but does not attempt a
// full deep-translation catalog. Dynamic content (product names, reviews,
// user-entered text) is never translated.
const I18N = (() => {
  const LANGS = { en: 'English', hi: 'हिन्दी', ta: 'தமிழ்', te: 'తెలుగు', kn: 'ಕನ್ನಡ' };

  const STRINGS = {
    navHome: { en: 'Home', hi: 'होम', ta: 'முகப்பு', te: 'హోమ్', kn: 'ಮುಖಪುಟ' },
    navShop: { en: 'Shop', hi: 'शॉप', ta: 'கடை', te: 'షాప్', kn: 'ಶಾಪ್' },
    navCombos: { en: 'Combos', hi: 'कॉम्बो', ta: 'கூட்டு சலுகைகள்', te: 'కాంబోలు', kn: 'ಕಾಂಬೊಗಳು' },
    navReviews: { en: 'Reviews', hi: 'रिव्यू', ta: 'விமர்சனங்கள்', te: 'రివ్యూలు', kn: 'ವಿಮರ್ಶೆಗಳು' },
    navBulk: { en: 'Bulk Enquiry', hi: 'बल्क पूछताछ', ta: 'மொத்த விசாரணை', te: 'బల్క్ విచారణ', kn: 'ಬಲ್ಕ್ ವಿಚಾರಣೆ' },
    navAbout: { en: 'About', hi: 'परिचय', ta: 'எங்களைப் பற்றி', te: 'మా గురించి', kn: 'ನಮ್ಮ ಬಗ್ಗೆ' },
    navContact: { en: 'Contact', hi: 'संपर्क करें', ta: 'தொடர்பு', te: 'సంప్రదించండి', kn: 'ಸಂಪರ್ಕಿಸಿ' },
    navLogin: { en: 'Login', hi: 'लॉगिन', ta: 'உள்நுழைய', te: 'లాగిన్', kn: 'ಲಾಗಿನ್' },
    navProfile: { en: 'Profile', hi: 'प्रोफ़ाइल', ta: 'சுயவிவரம்', te: 'ప్రొఫైల్', kn: 'ಪ್ರೊಫೈಲ್' },

    footerRights: { en: 'All rights reserved.', hi: 'सभी अधिकार सुरक्षित हैं।', ta: 'அனைத்து உரிமைகளும் பாதுகாக்கப்பட்டவை.', te: 'అన్ని హక్కులు రిజర్వు చేయబడ్డాయి.', kn: 'ಎಲ್ಲಾ ಹಕ್ಕುಗಳನ್ನು ಕಾಯ್ದಿರಿಸಲಾಗಿದೆ.' },

    heroBadge: { en: 'New Season', hi: 'नया सीज़न', ta: 'புதிய பருவம்', te: 'కొత్త సీజన్', kn: 'ಹೊಸ ಋತು' },
    heroCta: { en: 'Shop The Collection', hi: 'कलेक्शन देखें', ta: 'தொகுப்பைக் காண்க', te: 'కలెక్షన్ చూడండి', kn: 'ಸಂಗ್ರಹ ವೀಕ್ಷಿಸಿ' },
    forWomenTitle: { en: 'For Women', hi: 'महिलाओं के लिए', ta: 'பெண்களுக்கு', te: 'మహిళల కోసం', kn: 'ಮಹಿಳೆಯರಿಗಾಗಿ' },
    forMenTitle: { en: 'For Men', hi: 'पुरुषों के लिए', ta: 'ஆண்களுக்கு', te: 'పురుషుల కోసం', kn: 'ಪುರುಷರಿಗಾಗಿ' },
    featuredEyebrow: { en: 'Handpicked', hi: 'चुनिंदा', ta: 'தேர்ந்தெடுக்கப்பட்டவை', te: 'ఎంపిక చేసినవి', kn: 'ಆಯ್ದ' },
    featuredTitle: { en: 'Featured Pieces', hi: 'फीचर्ड कलेक्शन', ta: 'சிறப்பு பொருட்கள்', te: 'ఫీచర్డ్ పీసెస్', kn: 'ವಿಶಿಷ್ಟ ವಸ್ತುಗಳು' },
    viewAll: { en: 'View all →', hi: 'सभी देखें →', ta: 'அனைத்தையும் காண்க →', te: 'అన్నీ చూడండి →', kn: 'ಎಲ್ಲವನ್ನೂ ವೀಕ್ಷಿಸಿ →' },

    shopBannerTitle: { en: 'Shop The Collection', hi: 'कलेक्शन खरीदें', ta: 'தொகுப்பை வாங்குங்கள்', te: 'కలెక్షన్ షాప్ చేయండి', kn: 'ಸಂಗ್ರಹ ಖರೀದಿಸಿ' },
    shopBannerSub: { en: 'Considered essentials, for every day', hi: 'हर दिन के लिए चुनी हुई ज़रूरी चीज़ें', ta: 'அன்றாடம் அணிய தேர்ந்தெடுக்கப்பட்டவை', te: 'ప్రతిరోజూ కోసం ఎంపిక చేసినవి', kn: 'ಪ್ರತಿದಿನಕ್ಕೂ ಆಯ್ದ ವಸ್ತುಗಳು' },

    cartBannerTitle: { en: 'Your Cart', hi: 'आपका कार्ट', ta: 'உங்கள் கார்ட்', te: 'మీ కార్ట్', kn: 'ನಿಮ್ಮ ಕಾರ್ಟ್' },
    cartBannerSub: { en: 'Review your selections before checkout', hi: 'चेकआउट से पहले अपनी चीज़ें देखें', ta: 'செக்அவுட் முன் உங்கள் தேர்வுகளை பார்க்கவும்', te: 'చెక్అవుట్‌కు ముందు మీ ఎంపికలను చూడండి', kn: 'ಚೆಕ್‌ಔಟ್‌ಗೆ ಮೊದಲು ನಿಮ್ಮ ಆಯ್ಕೆಗಳನ್ನು ನೋಡಿ' },
    checkoutBtn: { en: 'Checkout', hi: 'चेकआउट', ta: 'செக்அவுட்', te: 'చెక్అవుట్', kn: 'ಚೆಕ್‌ಔಟ್' },

    wishlistBannerTitle: { en: 'Your Wishlist', hi: 'आपकी विशलिस्ट', ta: 'உங்கள் விருப்பப்பட்டியல்', te: 'మీ విష్‌లిస్ట్', kn: 'ನಿಮ್ಮ ಬಯಕೆಪಟ್ಟಿ' },
    wishlistBannerSub: { en: "Pieces you're saving for later", hi: 'आपके पसंदीदा आइटम', ta: 'நீங்கள் சேமித்து வைத்தவை', te: 'మీరు తర్వాత కోసం సేవ్ చేసినవి', kn: 'ನೀವು ಉಳಿಸಿಟ್ಟ ವಸ್ತುಗಳು' },

    ordersBannerTitle: { en: 'My Orders', hi: 'मेरे ऑर्डर', ta: 'எனது ஆர்டர்கள்', te: 'నా ఆర్డర్‌లు', kn: 'ನನ್ನ ಆರ್ಡರ್‌ಗಳು' },
    ordersBannerSub: { en: 'Your past purchases', hi: 'आपकी पिछली खरीदारी', ta: 'உங்கள் முந்தைய கொள்முதல்கள்', te: 'మీ మునుపటి కొనుగోళ్లు', kn: 'ನಿಮ್ಮ ಹಿಂದಿನ ಖರೀದಿಗಳು' },

    aboutBannerTitle: { en: 'About Us', hi: 'हमारे बारे में', ta: 'எங்களைப் பற்றி', te: 'మా గురించి', kn: 'ನಮ್ಮ ಬಗ್ಗೆ' },
    aboutBannerSub: { en: 'The story behind The Shoolins', hi: 'द शूलिन्स की कहानी', ta: 'த ஷூலின்ஸ் கதை', te: 'ది షూలిన్స్ కథ', kn: 'ದಿ ಶೂಲಿನ್ಸ್ ಕಥೆ' },

    contactBannerTitle: { en: 'Contact Us', hi: 'संपर्क करें', ta: 'தொடர்பு கொள்ளுங்கள்', te: 'మమ్మల్ని సంప్రదించండి', kn: 'ನಮ್ಮನ್ನು ಸಂಪರ್ಕಿಸಿ' },
    contactBannerSub: { en: "We'd love to hear from you", hi: 'हमें आपसे सुनना अच्छा लगेगा', ta: 'உங்களிடமிருந்து கேட்க விரும்புகிறோம்', te: 'మీ నుండి వినాలని అనుకుంటున్నాము', kn: 'ನಿಮ್ಮಿಂದ ಕೇಳಲು ಬಯಸುತ್ತೇವೆ' },

    combosBannerTitle: { en: 'Combo Offers', hi: 'कॉम्बो ऑफर', ta: 'கூட்டு சலுகைகள்', te: 'కాంబో ఆఫర్‌లు', kn: 'ಕಾಂಬೊ ಕೊಡುಗೆಗಳು' },
    combosBannerSub: { en: 'Frequently bought together, priced together', hi: 'साथ खरीदी जाने वाली चीज़ें', ta: 'ஒன்றாக வாங்கப்படுபவை', te: 'కలిసి కొనుగోలు చేసేవి', kn: 'ಒಟ್ಟಿಗೆ ಖರೀದಿಸುವ ವಸ್ತುಗಳು' },
    addBundleBtn: { en: 'Add Bundle to Cart', hi: 'बंडल कार्ट में जोड़ें', ta: 'தொகுப்பை கார்ட்டில் சேர்க்க', te: 'బండిల్‌ను కార్ట్‌కు జోడించండి', kn: 'ಬಂಡಲ್ ಅನ್ನು ಕಾರ್ಟ್‌ಗೆ ಸೇರಿಸಿ' },

    reviewsBannerTitle: { en: 'Customer Reviews', hi: 'ग्राहक रिव्यू', ta: 'வாடிக்கையாளர் விமர்சனங்கள்', te: 'కస్టమర్ రివ్యూలు', kn: 'ಗ್ರಾಹಕ ವಿಮರ್ಶೆಗಳು' },
    reviewsBannerSub: { en: "What our customers are saying", hi: 'हमारे ग्राहक क्या कहते हैं', ta: 'எங்கள் வாடிக்கையாளர்கள் கூறுவது', te: 'మా కస్టమర్‌లు ఏమి చెబుతున్నారు', kn: 'ನಮ್ಮ ಗ್ರಾಹಕರು ಏನು ಹೇಳುತ್ತಾರೆ' },
    writeReviewBtn: { en: 'Write a Review', hi: 'रिव्यू लिखें', ta: 'விமர்சனம் எழுதுங்கள்', te: 'రివ్యూ రాయండి', kn: 'ವಿಮರ್ಶೆ ಬರೆಯಿರಿ' },

    bulkBannerTitle: { en: 'Bulk & Wholesale Enquiries', hi: 'बल्क और थोक पूछताछ', ta: 'மொத்த விற்பனை விசாரணை', te: 'బల్క్ & టోకు విచారణలు', kn: 'ಬಲ್ಕ್ ಮತ್ತು ಸಗಟು ವಿಚಾರಣೆ' },
    bulkBannerSub: { en: 'For boutiques, retailers, and corporate orders', hi: 'बुटीक, रीटेलर और कॉर्पोरेट ऑर्डर के लिए', ta: 'பூட்டிக், சில்லறை மற்றும் நிறுவன ஆர்டர்களுக்கு', te: 'బొటిక్‌లు, రిటైలర్‌లు మరియు కార్పొరేట్ ఆర్డర్‌ల కోసం', kn: 'ಬೌಟಿಕ್, ರೀಟೇಲರ್ ಮತ್ತು ಕಾರ್ಪೊರೇಟ್ ಆರ್ಡರ್‌ಗಳಿಗಾಗಿ' },
    submitEnquiryBtn: { en: 'Submit Enquiry', hi: 'पूछताछ भेजें', ta: 'விசாரணையை அனுப்பவும்', te: 'విచారణ పంపండి', kn: 'ವಿಚಾರಣೆ ಸಲ್ಲಿಸಿ' },

    profileBannerLogout: { en: 'Log Out', hi: 'लॉग आउट', ta: 'வெளியேறு', te: 'లాగ్ అవుట్', kn: 'ಲಾಗ್ ಔಟ್' },
    addToCartBtn: { en: 'Add to Cart', hi: 'कार्ट में डालें', ta: 'கார்ட்டில் சேர்க்க', te: 'కార్ట్‌కు జోడించండి', kn: 'ಕಾರ್ಟ್‌ಗೆ ಸೇರಿಸಿ' },
    buyNowBtn: { en: 'Buy Now', hi: 'अभी खरीदें', ta: 'இப்போது வாங்கு', te: 'ఇప్పుడు కొనండి', kn: 'ಈಗ ಖರೀದಿಸಿ' },
  };

  function getLang() { return localStorage.getItem('shop_lang') || 'en'; }
  function setLang(lang) { localStorage.setItem('shop_lang', lang); }

  function t(key) {
    const entry = STRINGS[key];
    if (!entry) return key;
    return entry[getLang()] || entry.en;
  }

  function apply(root) {
    (root || document).querySelectorAll('[data-i18n]').forEach((el) => {
      el.textContent = t(el.getAttribute('data-i18n'));
    });
    (root || document).querySelectorAll('[data-i18n-placeholder]').forEach((el) => {
      el.placeholder = t(el.getAttribute('data-i18n-placeholder'));
    });
  }

  return { LANGS, getLang, setLang, t, apply };
})();
