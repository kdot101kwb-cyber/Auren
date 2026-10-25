#!/usr/bin/env python3
"""Collect public RSS headlines as market signals; this is not investment advice."""
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from html import unescape
from pathlib import Path
import re
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET

FEEDS = [
    ("Google News: AI apps and agents", "https://news.google.com/rss/search?q=AI+apps+agents+market&hl=en-US&gl=US&ceid=US:en"),
    ("Google News: mobile app startups", "https://news.google.com/rss/search?q=mobile+app+startup+consumer+apps&hl=en-US&gl=US&ceid=US:en"),
    ("Google News: small business automation", "https://news.google.com/rss/search?q=small+business+automation+AI+tools&hl=en-US&gl=US&ceid=US:en"),
    ("Hacker News front page", "https://hnrss.org/frontpage"),
]
KEYWORDS = {
    "AI agents": ("agent", "agentic", "autonomous"),
    "AI products": ("AI app", "AI tool", "artificial intelligence"),
    "mobile apps": ("mobile app", "android", "ios app"),
    "business demand": ("small business", "customer", "revenue", "subscription"),
    "developer tools": ("developer", "open source", "API", "coding"),
    "market movement": ("funding", "launch", "acquisition", "growth", "market"),
}

def clean(value):
    value = re.sub(r"<[^>]+>", " ", value or "")
    return re.sub(r"\\s+", " ", unescape(value)).strip()

def fetch(feed_name, url):
    request = urllib.request.Request(url, headers={"User-Agent": "NOVA-MarketRadar/1.0"})
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
            items.append({"source": feed_name, "title": title, "link": link, "description": description[:280], "date": date_text})
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
        text = (item["title"] + " " + item["description"]).lower()
        categories = [label for label, terms in KEYWORDS.items() if any(term.lower() in text for term in terms)]
        scored.append((len(categories), item, categories))
    scored.sort(key=lambda x: (-x[0], x[1]["date"], x[1]["title"]))
    lines = [
        "# NOVA — Daily Market Radar", "",
        f"- Generated: {now.strftime('%Y-%m-%d %H:%M UTC')}",
        "- Purpose: discover product and app-market signals for human review.",
        "- Evidence standard: headlines are signals, not proof of demand or profitability.",
        "- No purchases, investments, deployments, or repository changes are made by this workflow.",
        "", "## Summary", f"- Items collected: {len(unique)}",
        f"- Feeds with errors: {len(errors)}",
        "- This report does not establish market size, customer willingness to pay, or investment suitability.",
        "", "## Signals to inspect", "",
    ]
    if not scored:
        lines.append("No feed items were collected. Check the workflow logs and retry later.")
    for score, item, categories in scored[:30]:
        tags = ", ".join(categories) if categories else "Unclassified"
        lines += [
            f"### {item['title']}",
            f"- Date: {item['date']} | Feed: {item['source']} | Signal tags: {tags}",
            f"- Link: {item['link']}",
        ]
        if item["description"]:
            lines.append(f"- Snippet: {item['description']}")
        lines.append("")
    lines += [
        "## Suggested review checklist",
        "1. Is there a specific user problem repeated across independent sources?",
        "2. Can AUREN solve it with an existing module instead of a separate app?",
        "3. Who is the first user segment, and what evidence shows willingness to pay?",
        "4. Can a small prototype validate the idea without paid services?",
        "5. What are the privacy, security, support, and maintenance costs?",
        "", "## Feed errors",
    ]
    lines.extend(errors or ["- None"])
    output = Path("reports/nova-market-radar.md")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\\n".join(lines) + "\\n", encoding="utf-8")
    print(f"Wrote {output}; collected {len(unique)} unique items; feed errors={len(errors)}")

if __name__ == "__main__":
    main()
