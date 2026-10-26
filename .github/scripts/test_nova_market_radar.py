import unittest

from nova_market_radar import classify, clean


class MarketRadarTests(unittest.TestCase):
    def test_clean_removes_markup_and_collapses_whitespace(self):
        self.assertEqual(clean("<b>Remote</b>   job &amp; AI"), "Remote job & AI")

    def test_classifies_arabic_and_spanish_terms(self):
        self.assertIn("AI and data tasks", classify("تقييم الذكاء الاصطناعي", "وسم البيانات"))
        self.assertIn("language and localization", classify("trabajo de traducción", "traducción"))

    def test_classifies_chinese_and_hindi_terms(self):
        self.assertIn("AI and data tasks", classify("数据标注", "AI"))
        self.assertIn("language and localization", classify("अनुवाद", ""))

    def test_unrelated_headline_is_unclassified(self):
        self.assertEqual(classify("Weather forecast", "Sunny weekend"), [])


if __name__ == "__main__":
    unittest.main()
