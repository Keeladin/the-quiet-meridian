"""Narrow transcript-format exceptions supported by independent wording checks."""

FORMAT_VARIANTS = {
    ("mara", "mah ruh"), ("nadi", "nah dee"), ("elian", "el ee un"),
    ("sera", "seh ruh"), ("tomas", "thomas"), ("tomas's", "thomas's"),
    ("colour", "color"), ("neighbours", "neighbors"),
    ("authorisation", "authorization"), ("apologised", "apologized"),
    ("harbour", "harbor"),
    ("00 14", "zero zero fourteen"), ("00 22", "zero zero twenty two"),
}

NUMBER_FORMATS = {
    (("00", "14"), ("0014",)),
    (("00", "14"), ("zero", "zero", "fourteen")),
    (("00", "22"), ("0022",)),
    (("00", "22"), ("zero", "zero", "twenty", "two")),
    (("eight",), ("8",)),
}


def independent_wording_matches(review):
    comparison = review.get('independent_comparison', {})
    if comparison.get('passed'):
        return True
    changes = [item for item in comparison.get('opcodes', [])
               if item.get('operation') != 'equal']
    return bool(changes) and all(
        item.get('operation') == 'replace'
        and (tuple(item.get('expected', [])), tuple(item.get('observed', []))) in NUMBER_FORMATS
        for item in changes)


def provider_format_warning_only(receipt, review):
    """Never accept a lexical change, capture failure, or missing final usage."""
    result = receipt.get('result') or {}
    if receipt.get('status') != 'review_required' or result.get('usage_seconds') is None:
        return False
    if receipt.get('issue') != 'Spoken transcript differs from the script; review or request a new take':
        return False
    if not review.get('signal', {}).get('passed') or not independent_wording_matches(review):
        return False
    if review.get('clip_id') != receipt.get('id') or review.get('wav_sha256') != result.get('wav_sha256'):
        return False
    differences = result.get('quality', {}).get('differences', [])
    return bool(differences) and all(
        item.get('kind') == 'replace'
        and (item.get('script'), item.get('transcript')) in FORMAT_VARIANTS
        for item in differences)
