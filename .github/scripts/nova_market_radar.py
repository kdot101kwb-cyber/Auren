#!/usr/bin/env python3
"""Collect multilingual public RSS headlines as market signals, not financial advice."""
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from html import unescape
from pathlib import Path
from urllib.parse import quote_plus
import re
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET

# These feeds sample several languages and regions; they do not cover every language,
# country, platform, or active job. Every result must be verified at its source.
FEED_QUERIES = [
    ("English / global AI work", "remote AI jobs data annotation transcription freelance", "en-US", "US", "en"),
    ("English / India digital work", "AI evaluation remote work language data jobs", "en-IN", "IN", "en"),
    ("Arabic / MENA", "وظائف عن بعد عمل حر ترجمة بيانات الذكاء الاصطناعي", "ar", "EG", "ar"),
    ("Spanish / Spain and global", "trabajo remoto freelance traducción anotación de datos IA", "es", "ES", "es"),
    ("French / Europe and global", "travail à distance freelance traduction annotation de données IA", "fr", "FR", "fr"),
    ("German / Europe", "Remote Arbeit freiberuflich KI Datenannotation Übersetzung", "de", "DE", "de"),
    ("Portuguese / Brazil", "trabalho remoto freelancer tradução anotação de dados inteligência artificial", "pt-BR", "BR", "pt"),
    ("Hindi / India", "घर से काम फ्रीलांस एआई डेटा एनोटेशन अनुवाद", "hi", "IN", "hi"),
    ("Chinese / Taiwan", "人工智能 远程工作 自由职业 数据标注 翻译", "zh-TW", "TW", "zh-Hant"),
    ("Japanese / Japan", "AI 在宅勤務 フリーランス データアノテーション 翻訳", "ja", "JP", "ja"),
    ("Turkish / Türkiye", "uzaktan çalışma serbest çalışma yapay zeka veri etiketleme çeviri", "tr", "TR", "tr"),
    ("Swahili / East Africa", "kazi mtandaoni kazi za mbali tafsiri data AI", "sw", "KE", "sw"),
    ("English / creator services", "remote creator jobs video editing translation writing AI evaluator", "en-US", "US", "en"),
    ("Hacker News front page", None, None, None, None),
]

FEEDS = [
    (
        name,
        "https://hnrss.org/frontpage" if query is None else
        f"https://news.google.com/rss/search?q={quote_plus(query)}&hl={hl}&gl={gl}&ceid={gl}:{ceid}",
    )
    for name, query, hl, gl, ceid in FEED_QUERIES
]

KEYWORDS = {
    "AI and data tasks": (
        "AI evaluation", "data annotation", "transcription", "speech data",
        "تقييم الذكاء الاصطناعي", "وسم البيانات", "تفريغ صوتي", "تسجيل صوتي",
        "anotación de datos", "transcripción", "annotation de données",
        "Datenannotation", "Datenbeschriftung", "anotação de dados",
        "डेटा एनोटेशन", "डेटा लेबलिंग", "数据标注", "音声データ", "veri etiketleme",
    ),
    "remote work and freelancing": (
        "remote job", "freelance", "work from home", "trabajo remoto",
        "travail à distance", "remote arbeit", "trabalho remoto",
        "घर से काम", "远程工作", "在宅勤務", "uzaktan çalışma", "kazi mtandaoni",
        "وظائف عن بعد", "عمل حر",
    ),
    "language and localization": (
        "translation", "localization", "proofreading", "traducción", "traduction",
        "übersetzung", "tradução", "अनुवाद", "翻译", "翻訳", "çeviri", "ترجمة", "توطين",
    ),
    "AI products and developer tools": (
        "AI app", "AI tool", "developer", "open source", "API", "coding",
        "تطبيق ذكاء اصطناعي", "أدوات المطورين", "código abierto", "logiciel libre",
        "开源", "オープンソース",
    ),
    "creator and small-business demand": (
        "creator", "small business", "customer", "subscription", "revenue",
        "صناع المحتوى", "مشروع صغير", "creador", "petite entreprise",
        "pequena empresa", "छोटा व्यवसाय",
    ),
    "funding and market movement": (
        "funding", "launch", "acquisition", "growth", "market",
        "تمويل", "إطلاق", "financiación", "lancement", "financiamento",
    ),
}


def clean(value):
    value = re.sub(r"<[^>]+>", " ", value or "")
    return re.sub(r"\s+", " ", unescape(value)).strip()


def classify(title, description):
    text = f"{title} {description}".casefold()
    return [label for label, terms in KEYWORDS.items()
            if any(term.casefold() in text for term in terms)]


def fetch(feed_name, url):
    request = urllib.request.Request(url, headers={"User-Agent": "NOVA-MarketRadar/1.1"})
    with urllib.request.urlopen(request, timeout=15) as response:
        root = ET.fromstring(response.read())
    items = []
    for item in root.findall(".//item")[:12]:
        title = clean(item.findtext("title"))
        link = clean(item.findtext("link"))
        description = clean(item.findtext("description"))
        date_text = item.findtext("pubDate") or ""
        try:
            date_text = parsedate_to_datetime(date_text).astimezone(timezone.utc).strftime("%Y-%m-%d")
        except (TypeError, ValueError, OverflowError):
            date_text = "date unavailable"
        if title and link:
            items.append({
                "source": feed_name, "title": title, "link": link,
                "description": description[:280], "date": date_text,
            })
    return items


def main():
    now = datetime.now(timezone.utc)
    all_items, errors = [], []
    for name, url in FEEDS:
        try:
            all_items.extend(fetch(name, url))
        except (OSError, urllib.error.URLError, ET.ParseError, TimeoutError) as error:
            errors.append(f"- {name}: {type(error).__name__}")
    unique, seen = [], set()
    for item in all_items:
        if item["link"] not in seen:
            seen.add(item["link"])
            unique.append(item)
    scored = []
    for item in unique:
        categories = classify(item["title"], item["description"])
        scored.append((len(categories), item, categories))
    scored.sort(key=lambda x: (-x[0], x[1]["date"], x[1]["title"]))
    lines = [
        "# NOVA — Daily Global Opportunity Radar", "",
        f"- Generated: {now.strftime('%Y-%m-%d %H:%M UTC')}",
        "- Coverage: public RSS headlines sampled from Arabic, English, Spanish, French, German, Portuguese, Hindi, Chinese, Japanese, Turkish, and Swahili queries.",
        "- Coverage limitation: this is not every language or country and does not enumerate all available jobs.",
        "- Evidence standard: headlines are weak discovery signals, not proof of eligibility, demand, or profitability.",
        "- No registrations, purchases, investments, deployments, or repository changes are made by this workflow.",
        "", "## Summary", f"- Unique items collected: {len(unique)}",
        f"- Feeds with errors: {len(errors)}",
        "- Verify each source, publication date, location restrictions, contract terms, and payout method before acting.",
        "", "## Signals to inspect", "",
    ]
    if not scored:
        lines.append("No feed items were collected. Check workflow logs and retry later.")
    for score, item, categories in scored[:50]:
        tags = ", ".join(categories) if categories else "Unclassified"
        lines += [
            f"### {item['title']}",
            f"- Date: {item['date']} | Feed/language: {item['source']} | Signal tags: {tags}",
            f"- Link: {item['link']}",
        ]
        if item["description"]:
            lines.append(f"- Snippet: {item['description']}")
        lines.append("")
    lines += [
        "## Sudan and payment eligibility checklist",
        "1. Does the official listing explicitly accept applicants who live in Sudan?",
        "2. Can the platform legally onboard and verify the applicant's identity?",
        "3. Is a payout method available in Sudan, including its fees and minimum withdrawal?",
        "4. Is the opportunity currently open, and are its contract and tax terms clear?",
        "5. Never pay a registration fee to unlock a job; treat guaranteed-income claims as a warning sign.",
        "", "## Feed errors",
    ]
    lines.extend(errors or ["- None"])
    output = Path("reports/nova-market-radar.md")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {output}; collected {len(unique)} unique items; feed errors={len(errors)}")


if __name__ == "__main__":
    main()
