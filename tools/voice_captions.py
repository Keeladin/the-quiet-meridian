"""Use independent ASR word positions for readable, source-exact caption groups.

Alignment only estimates display timing; it never approves a word mismatch or
rewrites the dialogue to match recognition. Listening review remains separate.
"""
from difflib import SequenceMatcher
from voice_fidelity import _word_tokens


def captions(text, segments, duration):
    groups = []
    current = []
    for word in text.split():
        current.append(word)
        if len(current) >= 14 or (len(current) >= 5 and word.rstrip('\"\u201d\u2019\'').endswith(('.', '?', '!'))):
            groups.append(' '.join(current))
            current = []
    if current:
        groups.append(' '.join(current))
    expected = _word_tokens(text)
    heard = []
    timestamps = []
    for segment in segments:
        for word in segment['words']:
            tokens = _word_tokens(word['word'])
            heard.extend(tokens)
            timestamps.extend([float(word['start'])] * len(tokens))
    alignment = SequenceMatcher(a=expected, b=heard, autojunk=False)
    fallback = [{'start':0.0,'end':duration,'text':text}]
    if not expected or alignment.ratio() < 0.75:
        return fallback
    positions = {}
    for op, a, b, c, d in alignment.get_opcodes():
        if op == 'equal':
            for i in range(b-a):
                positions[a+i] = timestamps[c+i]
        elif op == 'replace' and d > c:
            for i in range(b-a):
                positions[a+i] = timestamps[min(d-1,c+int(i*(d-c)/max(1,b-a)))]
    starts = [0.0]
    index = len(_word_tokens(groups[0]))
    for group in groups[1:]:
        mapped = [i for i in positions if i >= index]
        if not mapped:
            return fallback
        starts.append(positions[min(mapped)])
        index += len(_word_tokens(group))
    ends = starts[1:] + [duration]
    if any(not (0 <= start < end <= duration) or end-start < 0.15 for start,end in zip(starts,ends)):
        return fallback
    result = [{'start':start,'end':end,'text':group} for group,start,end in zip(groups,starts,ends)]
    assert ' '.join(c['text'] for c in result) == ' '.join(text.split())
    return result
