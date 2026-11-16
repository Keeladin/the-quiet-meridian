import copy
import sys
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from voice_review import provider_format_warning_only

class TranscriptWarningTests(unittest.TestCase):
    def setUp(self):
        self.receipt={'id':'clip','status':'review_required','issue':'Spoken transcript differs from the script; review or request a new take',
            'result':{'usage_seconds':5,'wav_sha256':'hash','quality':{'differences':[{'kind':'replace','script':'mara','transcript':'mah ruh'}]}}}
        self.review={'clip_id':'clip','wav_sha256':'hash','signal':{'passed':True},'independent_comparison':{'passed':True}}
    def test_phonetic_transcript_with_independent_exact_audio_check(self):
        self.assertTrue(provider_format_warning_only(self.receipt,self.review))
    def test_word_change_or_insertion_never_waived(self):
        for change in [{'kind':'replace','script':'around','transcript':'here'}, {'kind':'replace','script':'you are','transcript':"you're"}, {'kind':'insert','script':'','transcript':'mara'}]:
            r=copy.deepcopy(self.receipt);r['result']['quality']['differences'].append(change)
            self.assertFalse(provider_format_warning_only(r,self.review))
    def test_requires_matching_independent_evidence_and_signal(self):
        for key,value in [('clip_id','different'),('wav_sha256','different'),('signal',{'passed':False}),('independent_comparison',{'passed':False})]:
            review=copy.deepcopy(self.review);review[key]=value
            self.assertFalse(provider_format_warning_only(self.receipt,review))
    def test_capture_and_billing_failures_cannot_be_overridden(self):
        for key,value in [('issue','Session time limit reached; the clip may be incomplete'),('status','billing_unknown')]:
            r=copy.deepcopy(self.receipt);r[key]=value
            self.assertFalse(provider_format_warning_only(r,self.review))
        self.receipt['result']['usage_seconds']=None
        self.assertFalse(provider_format_warning_only(self.receipt,self.review))

    def test_equivalent_timeline_notation_but_never_changed_words_or_times(self):
        self.receipt['result']['quality']['differences']=[
            {'kind':'replace','script':'00 14','transcript':'zero zero fourteen'},
            {'kind':'replace','script':'00 22','transcript':'zero zero twenty two'}]
        self.review['independent_comparison']={'passed':False,'opcodes':[
            {'operation':'replace','expected':['00','14'],'observed':['0014']},
            {'operation':'replace','expected':['00','22'],'observed':['0022']}]}
        self.assertTrue(provider_format_warning_only(self.receipt,self.review))
        for difference in [
            {'operation':'replace','expected':['open'],'observed':['opened']},
            {'operation':'replace','expected':['00','22'],'observed':['0042']},
            {'operation':'delete','expected':['00'],'observed':[]}]:
            review=copy.deepcopy(self.review);review['independent_comparison']['opcodes'].append(difference)
            self.assertFalse(provider_format_warning_only(self.receipt,review))

if __name__=='__main__': unittest.main()
