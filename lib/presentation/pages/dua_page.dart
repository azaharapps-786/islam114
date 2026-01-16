import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/settings_service.dart';

class DuaPage extends StatefulWidget {
  final String language; // 'english', 'hindi', 'bengali', 'assamese'
  final String title;

  const DuaPage({super.key, required this.language, required this.title});

  @override
  State<DuaPage> createState() => _DuaPageState();
}

class _DuaPageState extends State<DuaPage> {
  int? _highlightedIndex;

  static const Color _highlightColor = Color(0xFFFFF9C4);
  static const Color _highlightBorderColor = Color(0xFFFBC02D);

  // Helper method to get the correct language list
  List<Map<String, String>> _getLocalizedList() {
    switch (widget.language.toLowerCase()) {
      case 'hindi':
        return hindiDuas;
      case 'bengali':
        return bengaliDuas;
      case 'assamese':
        return assameseDuas;
      default:
        return englishDuas;
    }
  }

  // --- DATA SETS (2 Samples Each) ---

  static const List<Map<String, String>> englishDuas = [
    {
      "arabic": "رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنْتَ السَّمِيعُ الْعَلِيمُ",
      "transliteration": "Rabbana taqabbal minna innaka antas Samee'ul Aleem",
      "translation": "Our Lord! Accept (this service) from us: For Thou art the All-Hearing, the All-knowing.",
      "reference": "Surah Al-Baqarah (2:127)"
    },
    {
      "arabic": "رَبَّنَا وَاجْعَلْنَا مُسْلِمَيْنِ لَكَ وَمِنْ ذُرِّيَّتِنَا أُمَّةً مُسْلِمَةً لَكَ وَأَرِنَا مَنَاسِكَنَا وَتُبْ عَلَيْنَا إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ",
      "transliteration": "Rabbana wa-j'alna muslimayni laka wa min dhurriyyatina ummatan muslimatan laka wa arina manasikana wa tub 'alayna innaka antat Tawwabur Raheem",
      "translation": "Our Lord! Make of us Muslims, bowing to Thy (Will), and of our progeny a people Muslim, bowing to Thy (will); and show us our place for the celebration of (due) rites; and turn unto us (in Mercy); for Thou art the Oft-Returning, Most Merciful.",
      "reference": "Surah Al-Baqarah (2:128)"
    },
    {
      "arabic": "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
      "transliteration": "Rabbana atina fid-dunya hasanatan wa fil akhirati hasanatan waqina 'adhaban-nar",
      "translation": "Our Lord! Give us in this world that which is good and in the Hereafter that which is good, and save us from the torment of the Fire!",
      "reference": "Surah Al-Baqarah (2:201)"
    },
    {
      "arabic": "رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَثَبِّتْ أَقْدَامَنَا وَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ",
      "transliteration": "Rabbana afrigh 'alayna sabran wa thabbit aqdamana wansurna 'alal qawmil kafireen",
      "translation": "Our Lord! Bestow on us endurance, make our foothold sure, and give us help against the disbelieving folk.",
      "reference": "Surah Al-Baqarah (2:250)"
    },
    {
      "arabic": "رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا",
      "transliteration": "Rabbana la tu'akhidhna in naseena aw akhta'na",
      "translation": "Our Lord! Condemn us not if we forget or fall into error.",
      "reference": "Surah Al-Baqarah (2:286)"
    },
    {
      "arabic": "رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا",
      "transliteration": "Rabbana wala tahmil 'alayna isran kama hamaltahu 'alal-ladheena min qablina",
      "translation": "Our Lord! Lay not on us a burden Like that which Thou didst lay on those before us.",
      "reference": "Surah Al-Baqarah (2:286)"
    },
    {
      "arabic": "رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ",
      "transliteration": "Rabbana wala tuhammilna ma la taqata lana bihi wa'fu 'anna waghfir lana warhamna anta mawlana fansurna 'alal qawmil kafireen",
      "translation": "Our Lord! Lay not on us a burden greater than we have strength to bear. Blot out our sins, and grant us forgiveness. Have mercy on us. Thou art our Protector; Help us against those who stand against faith.",
      "reference": "Surah Al-Baqarah (2:286)"
    },
    {
      "arabic": "رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً ۚ إِنَّكَ أَنْتَ الْوَهَّابُ",
      "transliteration": "Rabbana la tuzigh qulubana ba'da idh hadaytana wa hab lana milladunka rahmah innaka antal Wahhab",
      "translation": "Our Lord! (they say), let not our hearts deviate now after Thou hast guided us, but grant us mercy from Thine own Presence; for Thou art the Grantor of bounties without measure.",
      "reference": "Surah Ali 'Imran (3:8)"
    },
    {
      "arabic": "رَبَّنَا إِنَّكَ جَامِعُ النَّاسِ لِيَوْمٍ لَا رَيْبَ فِيهِ ۚ إِنَّ اللَّهَ لَا يُخْلِفُ الْمِيعَادَ",
      "transliteration": "Rabbana innaka jami'un-nasi li-yawmil la rayba feehi innal-laha la yukhliful mee'aad",
      "translation": "Our Lord! Thou art He that will gather mankind Together against a Day about which there is no doubt; for Allah never fails in His promise.",
      "reference": "Surah Ali 'Imran (3:9)"
    },
    {
      "arabic": "رَبَّنَا إِنَّنَا آمَنَّا فَاغْفِرْ لَنَا ذُنُوبَنَا وَقِنَا عَذَابَ النَّارِ",
      "transliteration": "Rabbana innana amanna faghfir lana dhunubana wa qina 'adhaban-nar",
      "translation": "Our Lord! We have indeed believed: forgive us, then, our sins, and save us from the agony of the Fire.",
      "reference": "Surah Ali 'Imran (3:16)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا بِمَا أَنْزَلْتَ وَاتَّبَعْنَا الرَّسُولَ فَاكْتُبْنَا مَعَ الشَّاهِدِينَ",
      "transliteration": "Rabbana amanna bima anzalta wattaba'nar-Rasula faktubna ma'ash-shahideen",
      "translation": "Our Lord! We believe in what Thou hast revealed, and we follow the Messenger; then write us down among those who bear witness.",
      "reference": "Surah Ali 'Imran (3:53)"
    },
    {
      "arabic": "رَبَّنَا اغْفِرْ لَنَا ذُنُوبَنَا وَإِسْرَافَنَا فِي أَمْرِنَا وَثَبِّتْ أَقْدَامَنَا وَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ",
      "transliteration": "Rabbana-ghfir lana dhunubana wa israfana fee amrina wa thabbit aqdamana wansurna 'alal qawmil kafireen",
      "translation": "Our Lord! Forgive us our sins and anything we may have done that transgressed our duty: Establish our feet firmly, and help us against those that resist Faith.",
      "reference": "Surah Ali 'Imran (3:147)"
    },
    {
      "arabic": "رَبَّنَا مَا خَلَقْتَ هَٰذَا بَاطِلًا سُبْحَانَكَ فَقِنَا عَذَابَ النَّارِ",
      "transliteration": "Rabbana ma khalaqta hadha batila subhanaka faqina 'adhaban-nar",
      "translation": "Our Lord! Not for naught Hast Thou created (all) this! Glory to Thee! Give us salvation from the penalty of the Fire.",
      "reference": "Surah Ali 'Imran (3:191)"
    },
    {
      "arabic": "رَبَّنَا إِنَّكَ مَنْ تُدْخِلِ النَّارَ فَقَدْ أَخْزَيْتَهُ ۖ وَمَا لِلظَّالِمِينَ مِنْ أَنْصَارٍ",
      "transliteration": "Rabbana innaka man tudkhilin-nara faqad akhzaytahu wa ma liddhalimeena min ansar",
      "translation": "Our Lord! Any whom Thou dost admit to the Fire, Truly Thou coverest with shame, and never will wrong-doers Find any helpers!",
      "reference": "Surah Ali 'Imran (3:192)"
    },
    {
      "arabic": "رَبَّنَا إِنَّنَا سَمِعْنَا مُنَادِيًا يُنَادِي لِلْإِيمَانِ أَنْ آمِنُوا بِرَبِّكُمْ فَآمَنَّا",
      "transliteration": "Rabbana innana sami'na munadiyan yunadee lil-eemani an aminu bi-Rabbikum fa-amanna",
      "translation": "Our Lord! We have heard the call of one calling (Us) to Faith, 'Believe ye in the Lord,' and we have believed.",
      "reference": "Surah Ali 'Imran (3:193)"
    },
    {
      "arabic": "رَبَّنَا فَاغْفِرْ لَنَا ذُنُوبَنَا وَكَفِّرْ عَنَّا سَيِّئَاتِنَا وَتَوَفَّنَا مَعَ الْأَبْرَارِ",
      "transliteration": "Rabbana faghfir lana dhunubana wa kaffir 'anna sayyi'atina wa tawaffana ma'al abrar",
      "translation": "Our Lord! Forgive us our sins, blot out from us our iniquities, and take to Thyself our souls in the company of the righteous.",
      "reference": "Surah Ali 'Imran (3:193)"
    },
    {
      "arabic": "رَبَّنَا وَآتِنَا مَا وَعَدْتَنَا عَلَىٰ رُسُلِكَ وَلَا تُخْزِنَا يَوْمَ الْقِيَامَةِ ۗ إِنَّكَ لَا تُخْلِفُ الْمِيعَادَ",
      "transliteration": "Rabbana wa atina ma wa'adtana 'ala rusulika wala tukhzina yawmal qiyamah innaka la yukhliful mee'aad",
      "translation": "Our Lord! Grant us what Thou didst promise unto us through Thine apostles, and save us from shame on the Day of Judgment: For Thou never breakest Thy promise.",
      "reference": "Surah Ali 'Imran (3:194)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا فَاكْتُبْنَا مَعَ الشَّاهِدِينَ",
      "transliteration": "Rabbana amanna faktubna ma'ash-shahideen",
      "translation": "Our Lord! We believe; write us down among the witnesses.",
      "reference": "Surah Al-Ma'idah (5:83)"
    },
    {
      "arabic": "رَبَّنَا أَنْزِلْ عَلَيْنَا مَائِدَةً مِنَ السَّمَاءِ تَكُونُ لَنَا عِيدًا لِأَوَّلِنَا وَآخِرِنَا وَآيَةً مِنْكَ ۖ وَارْزُقْنَا وَأَنْتَ خَيْرُ الرَّازِقِينَ",
      "transliteration": "Rabbana anzil 'alayna ma'idatam minas-sama'i takunu lana 'eedal-li-awwalina wa akhirina wa ayatam minka warzuqna wa anta khayrur-raziqeen",
      "translation": "Our Lord! Send us from heaven a table set (with viands), that there may be for us - for the first and the last of us - a solemn festival and a sign from Thee; and provide for our sustenance, for Thou art the best Sustainer (of our needs).",
      "reference": "Surah Al-Ma'idah (5:114)"
    },
    {
      "arabic": "رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ",
      "transliteration": "Rabbana dhalamna anfusana wa-in lam taghfir lana wa tarhamna lanakunanna minal khasireen",
      "translation": "Our Lord! We have wronged our own souls: If Thou forgive us not and bestow not upon us Thy Mercy, we shall certainly be lost.",
      "reference": "Surah Al-A'raf (7:23)"
    },
    {
      "arabic": "رَبَّنَا لَا تَجْعَلْنَا مَعَ الْقَوْمِ الظَّالِمِينَ",
      "transliteration": "Rabbana la taj'alna ma'al qawmidh-dhalimeen",
      "translation": "Our Lord! Send us not to the company of the wrong-doers.",
      "reference": "Surah Al-A'raf (7:47)"
    },
    {
      "arabic": "رَبَّنَا افْتَحْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنْتَ خَيْرُ الْفَاتِحِينَ",
      "transliteration": "Rabbana-ftah baynana wa bayna qawmina bil haqqi wa anta khayrul fatiheen",
      "translation": "Our Lord! Decide Thou between us and our people in truth, for Thou art the best to decide.",
      "reference": "Surah Al-A'raf (7:89)"
    },
    {
      "arabic": "رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَتَوَفَّنَا مُسْلِمِينَ",
      "transliteration": "Rabbana afrigh 'alayna sabran wa tawaffana muslimeen",
      "translation": "Our Lord! Pour out on us patience and constancy, and take our souls unto Thee as Muslims (who bow to Thy will).",
      "reference": "Surah Al-A'raf (7:126)"
    },
    {
      "arabic": "رَبَّنَا لَا تَجْعَلْنَا فِتْنَةً لِلْقَوْمِ الظَّالِمِينَ وَنَجِّنَا بِرَحْمَتِكَ مِنَ الْقَوْمِ الْكَافِرِينَ",
      "transliteration": "Rabbana la taj'alna fitnatal-lil qawmidh-dhalimeen wa najjina bi-rahmatika minal qawmil kafireen",
      "translation": "Our Lord! Make us not a trial for those who practise oppression; And deliver us by Thy Mercy from those who reject (Thee).",
      "reference": "Surah Yunus (10:85-86)"
    },
    {
      "arabic": "رَبَّنَا إِنَّكَ تَعْلَمُ مَا نُخْفِي وَمَا نُعْلِنُ ۗ وَمَا يَخْفَىٰ عَلَى اللَّهِ مِنْ شَيْءٍ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ",
      "transliteration": "Rabbana innaka ta'lamu ma nukhfee wa ma nu'lin wa ma yakhfa 'alal-lahi min shay'in fil ardi wala fis-sama'",
      "translation": "Our Lord! Truly Thou dost know what we conceal and what we reveal: for nothing whatever is hidden from Allah, whether on earth or in heaven.",
      "reference": "Surah Ibrahim (14:38)"
    },
    {
      "arabic": "رَبَّنَا وَتَقَبَّلْ دُعَاءِ",
      "transliteration": "Rabbana wa taqabbal du'a",
      "translation": "Our Lord! And accept my Prayer.",
      "reference": "Surah Ibrahim (14:40)"
    },
    {
      "arabic": "رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ",
      "transliteration": "Rabbana-ghfir lee waliwa lidayya walil mu'mineena yawma yaqumul hisab",
      "translation": "Our Lord! Cover (us) with Thy Forgiveness - me, my parents, and (all) Believers, on the Day that the Reckoning will be established!",
      "reference": "Surah Ibrahim (14:41)"
    },
    {
      "arabic": "رَبَّنَا آتِنَا مِنْ لَدُنْكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا",
      "transliteration": "Rabbana atina milladunka rahmatan wa hayyi' lana min amrina rashada",
      "translation": "Our Lord! Bestow on us Mercy from Thine own Presence, and dispose of our affair for us in the right way!",
      "reference": "Surah Al-Kahf (18:10)"
    },
    {
      "arabic": "رَبَّنَا إِنَّنَا نَخَافُ أَنْ يَفْرُطَ عَلَيْنَا أَوْ أَنْ يَطْغَىٰ",
      "transliteration": "Rabbana innana nakhafu ay-yafruta 'alayna aw ay-yatgha",
      "translation": "Our Lord! We fear lest he hasten with insolence against us, or lest he transgress all bounds.",
      "reference": "Surah Ta-Ha (20:45)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا فَاغْفِرْ لَنَا وَارْحَمْنَا وَأَنْتَ خَيْرُ الرَّاحِمِينَ",
      "transliteration": "Rabbana amanna faghfir lana warhamna wa anta khayrur rahimin",
      "translation": "Our Lord! We believe; then do Thou forgive us, and have mercy upon us: For Thou art the Best of those who show mercy!",
      "reference": "Surah Al-Mu'minun (23:109)"
    },
    {
      "arabic": "رَبَّنَا اصْرِفْ عَنَّا عَذَابَ جَهَنَّمَ ۖ إِنَّ عَذَابَهَا كَانَ غَرَامًا",
      "transliteration": "Rabbanas-rif 'anna 'adhaba jahannama inna 'adhabaha kana gharama",
      "translation": "Our Lord! Avert from us the Wrath of Hell, for its Wrath is indeed an affliction grievous.",
      "reference": "Surah Al-Furqan (25:65)"
    },
    {
      "arabic": "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا",
      "transliteration": "Rabbana hab lana min azwajina wa dhurriyyatina qurrata a'yunin waj'alna lil muttaqeena imama",
      "translation": "Our Lord! Grant unto us wives and offspring who will be the comfort of our eyes, and give us (the grace) to lead the righteous.",
      "reference": "Surah Al-Furqan (25:74)"
    },
    {
      "arabic": "رَبَّنَا لَغَفُورٌ شَكُورٌ",
      "transliteration": "Rabbana la Ghafurun Shakur",
      "translation": "Our Lord is indeed Oft-Forgiving Ready to appreciate (service).",
      "reference": "Surah Fatir (35:34)"
    },
    {
      "arabic": "رَبَّنَا وَسِعْتَ كُلَّ شَيْءٍ رَحْمَةً وَعِلْمًا فَاغْفِرْ لِلَّذِينَ تَابُوا وَاتَّبَعُوا سَبِيلَكَ وَقِهِمْ عَذَابَ الْجَحِيمِ",
      "transliteration": "Rabbana wasi'ta kulla shay'ir rahmataw-wa 'ilman faghfir lilladheena tabu wattaba'u sabeelaka waqihim 'adhabal jaheem",
      "translation": "Our Lord! Thy Reach is over all things, in Mercy and Knowledge. Forgive, then, those who turn in Repentance, and follow Thy Path; and preserve them from the Penalty of the Blazing Fire!",
      "reference": "Surah Ghafir (40:7)"
    },
    {
      "arabic": "رَبَّنَا وَأَدْخِلْهُمْ جَنَّاتِ عَدْنٍ الَّتِي وَعَدْتَهُمْ وَمَنْ صَلَحَ مِنْ آبَائِهِمْ وَأَزْوَاجِهِمْ وَذُرِّيَّاتِهِمْ ۚ إِنَّكَ أَنْتَ الْعَزِيزُ الْحَكِيمُ",
      "transliteration": "Rabbana wa adkhilhum jannati 'adninil-latee wa'adtahum wa man salaha min aba'ihim wa azwajihim wa dhurriyyatihim innaka antal 'Azeezul Hakeem",
      "translation": "And grant, our Lord! that they enter the Gardens of Eternity, which Thou hast promised to them, and to the righteous among their fathers, their wives, and their posterity! For Thou art (He), the Exalted in Might, Full of Wisdom.",
      "reference": "Surah Ghafir (40:8)"
    },
    {
      "arabic": "رَبَّنَا اغْفِرْ لَنَا وَلِإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالْإِيمَانِ وَلَا تَجْعَلْ فِي قُلُوبِنَا غِلًّا لِلَّذِينَ آمَنُوا رَبَّنَا إِنَّكَ رَءُوفٌ رَحِيمٌ",
      "transliteration": "Rabbana-ghfir lana wa li-ikhwaninal-ladheena sabaquna bil-eemani wala taj'al fee qulubina ghillal-lilladheena amanu Rabbana innaka Ra'ufur Raheem",
      "translation": "Our Lord! Forgive us, and our brethren who came before us into the Faith, and leave not, in our hearts, rancour (or sense of injury) against those who have believed. Our Lord! Thou art indeed Full of Kindness, Most Merciful.",
      "reference": "Surah Al-Hashr (59:10)"
    },
    {
      "arabic": "رَبَّنَا عَلَيْكَ تَوَكَّلْنَا وَإِلَيْكَ أَنَبْنَا وَإِلَيْكَ الْمَصِيرُ",
      "transliteration": "Rabbana 'alayka tawakkalna wa ilayka anabna wa ilaykal maseer",
      "translation": "Our Lord! In Thee do we trust, and to Thee do we turn in repentance: to Thee is (our) Final Goal.",
      "reference": "Surah Al-Mumtahanah (60:4)"
    },
    {
      "arabic": "رَبَّنَا لَا تَجْعَلْنَا فِتْنَةً لِلَّذِينَ كَفَرُوا وَاغْفِرْ لَنَا رَبَّنَا ۖ إِنَّكَ أَنْتَ الْعَزِيزُ الْحَكِيمُ",
      "transliteration": "Rabbana la taj'alna fitnatal-lilladheena kafaru waghfir lana Rabbana innaka antal 'Azeezul Hakeem",
      "translation": "Our Lord! Make us not a (test and) trial for the Unbelievers, but forgive us, our Lord! for Thou art the Exalted in Might, Full of Wisdom.",
      "reference": "Surah Al-Mumtahanah (60:5)"
    },
    {
      "arabic": "رَبَّنَا أَتْمِمْ لَنَا نُورَنَا وَاغْفِرْ لَنَا ۖ إِنَّكَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ",
      "transliteration": "Rabbana atmim lana nurana waghfir lana innaka 'ala kulli shay'in qadeer",
      "translation": "Our Lord! Perfect our Light for us, and grant us Forgiveness: for Thou hast power over all things.",
      "reference": "Surah At-Tahrim (66:8)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا فَاغْفِرْ لَنَا ذُنُوبَنَا وَقِنَا عَذَابَ النَّارِ",
      "transliteration": "Rabbana amanna faghfir lana dhunubana wa qina 'adhaban-nar",
      "translation": "Our Lord! we have indeed believed: forgive us, then, our sins, and save us from the agony of the Fire.",
      "reference": "Surah Ali 'Imran (3:16)"
    },
  ];

  static const List<Map<String, String>> hindiDuas = [
    {
      "arabic": "رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنْتَ السَّمِيعُ الْعَلِيمُ",
      "transliteration": "रब्बना तक़ब्बल मिन्ना इन्नका अन्तस समीउल अलीम",
      "translation": "ऐ हमारे रब! हमारी तरफ से (इसे) कुबूल फरमा; बेशक तू ही सब कुछ सुनने वाला और जानने वाला है।",
      "reference": "Surah Al-Baqarah (2:127)"
    },
    {
      "arabic": "رَبَّनَا وَاجْعَلْنَا مُسْلِمَيْنِ لَكَ وَمِنْ ذُرِّيَّتِنَا أُمَّةً مُسْلِمَةً لَكَ وَأَرِنَا مَنَاسِكَنَا وَتُبْ عَلَيْنَا إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ",
      "transliteration": "रब्बना वजअल्ना मुस्लिमैनी लका व मिन जुर्रिय्यतिना उम्म़तम मुस्लिमतल लका व अरिना मनासिकाना व तुब अलैना इन्नका अन्तत तव्वाबुर रहीम",
      "translation": "ऐ हमारे रब! हमें अपना फरमाबरदार (मुस्लिम) बना और हमारी औलाद में से भी एक ऐसी उम्मत बना जो तेरी फरमाबरदार हो; हमें इबादत के तरीके सिखा और हमारी तौबा कुबूल कर। बेशक तू तौबा कुबूल करने वाला, निहायत रहम करने वाला है।",
      "reference": "Surah Al-Baqarah (2:128)"
    },
    {
      "arabic": "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
      "transliteration": "रब्बना आतिना फिद-दुनिया हसनतंव व फिल आखिरति हसनतंव वकिना अज़ाबन नार",
      "translation": "ऐ हमारे रब! हमें दुनिया में भी भलाई दे और आखिरत में भी भलाई दे, और हमें आग (दोज़ख) के अज़ाब से बचा।",
      "reference": "Surah Al-Baqarah (2:201)"
    },
    {
      "arabic": "رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَثَبِّتْ أَقْدَامَنَا وَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ",
      "transliteration": "रब्बना अफ्रिग अलैना सबरंव व सब्बित अकदामाना वन्सुरना अलल कौमिल काफ़िरीन",
      "translation": "ऐ हमारे रब! हम पर सब्र उंडेल दे, हमारे कदमों को जमाए रख और काफिरों की कौम के खिलाफ हमारी मदद फरमा।",
      "reference": "Surah Al-Baqarah (2:250)"
    },
    {
      "arabic": "رَبَّنَا لَا تُؤَاखِذْنَا إِنْ نَسِينَا أَوْ أَखْطَأْنَا",
      "transliteration": "रब्बना ला तुआखिजना इन नसीना औ अख़ताना",
      "translation": "ऐ हमारे रब! अगर हम भूल जाएँ या चूक जाएँ तो हमारी पकड़ न करना।",
      "reference": "Surah Al-Baqarah (2:286)"
    },
    {
      "arabic": "رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا",
      "transliteration": "रब्बना वला तह्मिल अलैना इस्रन कमा हमल्तहु अलल लज़ीना मिन क़ब्लिना",
      "translation": "ऐ हमारे रब! हम पर वैसा बोझ न डाल जैसा तूने हमसे पहले लोगों पर डाला था।",
      "reference": "Surah Al-Baqarah (2:286)"
    },
    {
      "arabic": "رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ",
      "transliteration": "रब्बना वला तुहम्मिल्ना मा ला ताकता लना बिही वाफु अन्ना वग्फिर लना वरहम्ना अन्ता मौलाना वन्सुरना अलल कौमिल काफ़िरीन",
      "translation": "ऐ हमारे रब! हमसे वह बोझ न उठवा जिसकी हमें ताकत न हो। हमसे दरगुज़र फरमा, हमें बख्श दे और हम पर रहम कर। तू ही हमारा मालिक है, पस काफिरों के मुकाबले में हमारी मदद फरमा।",
      "reference": "Surah Al-Baqarah (2:286)"
    },
    {
      "arabic": "رَبَّنَا لَا تُزِغْ قُلُूबَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً ۚ إِنَّكَ أَنْتَ الْوَهَّابُ",
      "transliteration": "रब्बना ला तुज़िग कुलूबना बाद इज हदैतना व हब लना मिल लदुनका रहमह इन्नका अन्तल वह्वाब",
      "translation": "ऐ हमारे रब! हिदायत देने के बाद हमारे दिलों को टेढ़ा न होने दे और हमें अपने पास से रहमत अता फरमा। बेशक तू ही बहुत ज्यादा देने वाला है।",
      "reference": "Surah Ali 'Imran (3:8)"
    },
    {
      "arabic": "رَبَّنَا إِنَّكَ جَامِعُ النَّاسِ لِيَوْمٍ لَا رَيْبَ فِيهِ ۚ إِنَّ اللَّहَ لَا يُخْلِفُ الْمِيعَادَ",
      "transliteration": "रब्बना इन्नका जामिउन नासि लियौमिल ला रैबा फ़ीहि इन्नल्लाहा ला युख्लीफुल मीआद",
      "translation": "ऐ हमारे रब! तू तमाम इंसानों को उस दिन जमा करने वाला है जिसमें कोई शक नहीं; बेशक अल्लाह अपने वादे के खिलाफ नहीं करता।",
      "reference": "Surah Ali 'Imran (3:9)"
    },
    {
      "arabic": "رَبَّنَا إِنَّنَا آمَنَّا فَاغْفिरْ لَنَا ذُنُوبَنَا وَقِنَا عَذَابَ النَّارِ",
      "transliteration": "रब्बना इन्नना आमन्ना फ़ग्फ़िर लना ज़ुनूबना वक़िना अज़ाबन नार",
      "translation": "ऐ हमारे रब! हम ईमान लाए, पस हमारे गुनाह बख्श दे और हमें आग के अज़ाब से बचा।",
      "reference": "Surah Ali 'Imran (3:16)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا بِمَا أَنْزَلْتَ وَاتَّبَعْنَا الرَّسُولَ فَاكْتُبْنَا مَعَ الشَّاهِدِينَ",
      "transliteration": "रब्बना आमन्ना बिमा अनज़ल्ता वत्तबअनर रसूला फ़क्तुब्ना मअश शाहिदीन",
      "translation": "ऐ हमारे रब! जो तूने नाज़िल किया हम उस पर ईमान लाए और हमने रसूल की पैरवी की, पस हमें गवाही देने वालों में लिख ले।",
      "reference": "Surah Ali 'Imran (3:53)"
    },
    {
      "arabic": "رَبَّنَا اغْفِرْ لَنَا ذُنُوبَنَا وَإِسْرَافَنَا فِي أَمْرِنَا وَثَبِّتْ أَقْدَامَنَا وَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ",
      "transliteration": "रब्बना-ग़फ़िर लना ज़ुनूबना व इस्राफ़ना फ़ी अम्रिना व सब्बित अकदामाना वन्सुरना अलल कौमिल काफ़िरीन",
      "translation": "ऐ हमारे रब! हमारे गुनाह बख्श दे और हमारे कामों में जो ज़्यादती हुई है उसे भी, हमारे कदम जमाए रख और काफिरों की कौम पर हमें जीत अता कर।",
      "reference": "Surah Ali 'Imran (3:147)"
    },
    {
      "arabic": "رَبَّنَا مَا خَلَقْتَ هَٰذَا بَاطِلًا سُبْحَانَكَ فَقِنَا عَذَابَ النَّارِ",
      "transliteration": "रब्बना मा खलक्ता हाज़ा बातिलन सुब्हानका फ़किना अज़ाबन नार",
      "hindi": "ऐ हमारे रब! तूने यह सब बेकार पैदा नहीं किया। तू पाक है! पस हमें आग के अज़ाब से बचा।",
      "reference": "Surah Ali 'Imran (3:191)"
    },
    {
      "arabic": "رَبَّنَا إِنَّكَ مَنْ تُدْخِلِ النَّارَ فَقَدْ أَخْزَيْتَهُ ۖ وَمَا لِلظَّالِمِينَ مِنْ أَنْصَارٍ",
      "transliteration": "रब्बना इन्नका मन तुदखिलीन नारा फकद अख़ज़ैतहु व मा लिज्ज़ालिमीना मिन अंसार",
      "hindi": "ऐ हमारे रब! तूने जिसे आग में डाला उसे यकीनन रुसवा (अपमानित) किया, और ज़ालिमों का कोई मददगार न होगा।",
      "reference": "Surah Ali 'Imran (3:192)"
    },
    {
      "arabic": "رَبَّنَا إِنَّنَا سَمِعْنَا مُنَادِيًا يُنَادِي لِلْإِيمَانِ أَنْ آمِنُوا بِرَبِّكُمْ فَآمَنَّا",
      "transliteration": "रब्बना इन्नना समिअना मुनादियन युनादी लिल ईमानी अन आमीनू बिरब्बिकुम फ़आमन्ना",
      "hindi": "ऐ हमारे रब! हमने एक पुकारने वाले को सुना जो ईमान की तरफ बुला रहा था कि अपने रब पर ईमान लाओ, तो हम ईमान ले आए।",
      "reference": "Surah Ali 'Imran (3:193)"
    },
    {
      "arabic": "رَبَّنَا فَاغْفِرْ لَنَا ذُنُوبَنَا وَكَفِّرْ عَنَّا سَيِّئَاتِنَا وَتَوَفَّنَا مَعَ الْأَبْرَارِ",
      "transliteration": "रब्बना फ़ग्फ़िर लना ज़ुनूबना व कफ़्फ़िर अन्ना सय्यिआतिना व तवफ़्फ़ना मअल अबरार",
      "hindi": "ऐ हमारे रब! हमारे गुनाह बख्श दे, हमारी बुराइयों को हमसे दूर कर दे और हमारा खात्मा नेक लोगों के साथ कर।",
      "reference": "Surah Ali 'Imran (3:193)"
    },
    {
      "arabic": "رَبَّنَا وَآتِنَا مَا وَعَدْتَنَا عَلَىٰ رُسُلِكَ وَلَا تُخْزِنَا يَوْमَ الْقِيَامَةِ ۗ إِنَّكَ لَا تُخْلِفُ الْمِيعَادَ",
      "transliteration": "रब्बना व आतिना मा वअततना अला रुसुलिका वला तुख्रज़िना यौमल क़ियामह इन्नका ला तुखलीफुल मीआद",
      "hindi": "ऐ हमारे रब! हमें वह सब अता कर जिसका तूने अपने रसूलों के ज़रिए वादा किया है और कयामत के दिन हमें रुसवा न करना। बेशक तू वादे के खिलाफ नहीं करता।",
      "reference": "Surah Ali 'Imran (3:194)"
    },
    {
      "arabic": "رَبَّनَا آمَنَّا فَاكْتُبْنَا مَعَ الشَّاهِدِينَ",
      "transliteration": "रब्बना आमन्ना फ़क्तुब्ना मअश शाहिदीन",
      "hindi": "ऐ हमारे रब! हम ईमान लाए, पस हमें गवाही देने वालों में लिख ले।",
      "reference": "Surah Al-Ma'idah (5:83)"
    },
    {
      "arabic": "رَبَّنَا أَنْزِلْ عَلَيْنَا مَائِدَةً مِنَ السَّمَاءِ تَكُونُ لَنَا عِيدًا لِأَوَّلِنَا وَآخِرِنَا وَآيَةً مِنْكَ ۖ وَارْزُقْنَا وَأَنْتَ خَيْرُ الرَّازِقِينَ",
      "transliteration": "रब्बना अन्ज़िल अलैना माइदतम मिनस समाइ तकूनु लना ईदल लिअव्वलिना व आख़िरिना व आयतम मिंका वर्ज़ुक्ना व अन्ता खैरुर राज़िकीन",
      "hindi": "ऐ हमारे रब! हम पर आसमान से खाने का दस्तरख्वान नाज़िल फरमा, जो हमारे लिए और हमारे अगले-पिछलों के लिए खुशी का मौका बने और तेरी तरफ से एक निशानी हो। हमें रिज़्क अता फरमा, तू सबसे बेहतरीन रिज़्क देने वाला है।",
      "reference": "Surah Al-Ma'idah (5:114)"
    },
    {
      "arabic": "رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ",
      "transliteration": "रब्बना ज़लमना अन्फुसना व इल्ल़म तग्फिर लना व तरहम्ना लनकूनन्ना मिनल खास़िरीन",
      "hindi": "ऐ हमारे रब! हमने अपनी जानों पर ज़ुल्म किया; अगर तूने हमें न बख्शा और हम पर रहम न किया तो यकीनन हम नुकसान उठाने वालों में हो जाएँगे।",
      "reference": "Surah Al-A'raf (7:23)"
    },
    {
      "arabic": "رَبَّنَا لَا تَجْعَلْنَا مَعَ الْقَوْمِ الظَّالِمِينَ",
      "transliteration": "रब्बना ला तजअल्ना मअल कौमिज़ ज़ालिमीन",
      "hindi": "ऐ हमारे रब! हमें ज़ालिम लोगों के साथ शामिल न करना।",
      "reference": "Surah Al-A'raf (7:47)"
    },
    {
      "arabic": "رَبَّنَا افْتَحْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنْتَ خَيْرُ الْفَاتِحِينَ",
      "transliteration": "रब्बनाफ़्तह बैनना व बैना कौमिना बिल हक्की व अन्ता खैरुल फ़ातिहीन",
      "hindi": "ऐ हमारे रब! हमारे और हमारी कौम के दरमियान हक के साथ फैसला कर दे, और तू सबसे बेहतर फैसला करने वाला है।",
      "reference": "Surah Al-A'raf (7:89)"
    },
    {
      "arabic": "رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَتَوَفَّنَا مُسْلِمِينَ",
      "transliteration": "रब्बना अफ्रिग अलैना सबरंव व तवफ़्फ़ना मुस्लिमीन",
      "hindi": "ऐ हमारे रब! हम पर सब्र उंडेल दे और हमारा खात्मा इस्लाम पर (मुसलमान होने की हालत में) कर।",
      "reference": "Surah Al-A'raf (7:126)"
    },
    {
      "arabic": "رَبَّنَا لَا تَجْعَلْنَا فِتْنَةً لِلْقَوْمِ الظَّالِمِينَ وَنَجِّنَا بِرَحْمَتِكَ مِنَ الْقَوْमِ الْكَافِرِينَ",
      "transliteration": "रब्बना ला तजअल्ना फ़ित्नातल लिल कौमिज़ ज़ालिमीन व नज्जिना बिरहम़तिका मिनल कौमिल काफ़िरीन",
      "hindi": "ऐ हमारे रब! हमें ज़ालिमों के लिए आज़माइश न बना, और अपनी रहमत से हमें काफिरों की कौम से निजात (छुटकारा) दे।",
      "reference": "Surah Yunus (10:85-86)"
    },
    {
      "arabic": "رَبَّنَا إِنَّكَ تَعْلَمُ مَا نُخْفِي وَمَا نُعْلِنُ ۗ وَمَا يَخْفَىٰ عَلَى اللَّهِ مِنْ شَيْءٍ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ",
      "transliteration": "रब्बना इन्नका तअलमु मा नुख़फी व मा नुलिनु व मा यख़फा अलल्लाही मिन शैइन फ़िल अर्ज़ि वला फिस समाइ",
      "hindi": "ऐ हमारे रब! जो कुछ हम छुपाते हैं और जो ज़ाहिर करते हैं, तू यकीनन सब जानता है। ज़मीन और आसमान की कोई चीज़ अल्लाह से छुपी नहीं है।",
      "reference": "Surah Ibrahim (14:38)"
    },
    {
      "arabic": "رَبَّنَا وَتَقَبَّلْ دُعَاءِ",
      "transliteration": "रब्बना व तक़ब्बल दुआ",
      "hindi": "ऐ हमारे रब! मेरी दुआ कुबूल फरमा।",
      "reference": "Surah Ibrahim (14:40)"
    },
    {
      "arabic": "رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْमَ يَقُومُ الْحِسَابُ",
      "transliteration": "रब्बना-ग़फ़िर ली वलि वालिदैया वलिल मुअमिनीना यौमा यकूमुल हिसाब",
      "hindi": "ऐ हमारे रब! मुझे, मेरे वालिदैन (माता-पिता) को और तमाम मोमिनों को उस दिन बख्श देना जिस दिन हिसाब कायम होगा।",
      "reference": "Surah Ibrahim (14:41)"
    },
    {
      "arabic": "رَبَّنَا آتِنَا مِنْ لَدُنْكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا",
      "transliteration": "रब्बना आतिना मिल लदुनका रहमतंव व हय्यि लना मिन अम्रिना रशदा",
      "hindi": "ऐ हमारे रब! हमें अपने पास से रहमत अता फरमा और हमारे काम में सही राह (हिदायत) का सामान कर दे।",
      "reference": "Surah Al-Kahf (18:10)"
    },
    {
      "arabic": "رَبَّنَا إِنَّنَا نَخَافُ أَنْ يَفْرُطَ عَلَيْنَا أَوْ أَنْ يَطْغَىٰ",
      "transliteration": "रब्बना इन्नना नखाफु अंय यफृरुता अलैना औ अंय यतग़ा",
      "hindi": "ऐ हमारे रब! हमें डर है कि वह हम पर ज़्यादती न करे या अपनी सरकशी (विद्रोह) न बढ़ा दे।",
      "reference": "Surah Ta-Ha (20:45)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا فَاغْفِرْ لَنَا وَارْحَمْنَا وَأَنْتَ خَيْرُ الرَّاحِمِينَ",
      "transliteration": "रब्बना आमन्ना फ़ग्फ़िर लना वरहम्ना व अन्ता खैरुर राहिमीन",
      "hindi": "ऐ हमारे रब! हम ईमान लाए, पस हमें बख्श दे और हम पर रहम कर; तू सबसे बेहतर रहम करने वाला है।",
      "reference": "Surah Al-Mu'minun (23:109)"
    },
    {
      "arabic": "رَبَّنَا اصْرِفْ عَنَّا عَذَابَ جَهَنَّمَ ۖ إِنَّ عَذَابَهَا كَانَ غَرَامًا",
      "transliteration": "रब्बनास्रिफ अन्ना अज़ाबा जहन्नमा इन्ना अज़ाबहा काना गरामा",
      "hindi": "ऐ हमारे रब! हमसे जहन्नम का अज़ाब टाल दे, बेशक उसका अज़ाब चिमट जाने वाला (सख्त) है।",
      "reference": "Surah Al-Furqan (25:65)"
    },
    {
      "arabic": "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعएलْنَا لِلْمُتَّقِينَ إِمَامًا",
      "transliteration": "रब्बना हब लना मिन अज़वाजिना व जुर्रिय्यातिना कुर्रता अयुनंव वजअल्ना लिल मुत्तकीना इमामा",
      "hindi": "ऐ हमारे रब! हमें हमारी बीवियों और औलाद से आँखों की ठंडक अता फरमा और हमें मुत्तकियों (परहेजगारों) का इमाम बना।",
      "reference": "Surah Al-Furqan (25:74)"
    },
    {
      "arabic": "رَبَّنَا لَغَفُورٌ شَكُورٌ",
      "transliteration": "रब्बना लग़फ़ूरुन शकूर",
      "hindi": "हमारा रब यकीनन बहुत बख्शने वाला और कद्रदान है।",
      "reference": "Surah Fatir (35:34)"
    },
    {
      "arabic": "رَبَّنَا وَسِعْتَ كُلَّ شَيْءٍ رَحْمَةً وَعِلْمًا فَاغْفِرْ لِلَّذِينَ تَابُوا وَاتَّبَعُوا سَبِيلَكَ وَقِهِمْ عَذَابَ الْجَحِيمِ",
      "transliteration": "रब्बना वसिअता कुल्ला शैइर रहमतंव व इल्मन फ़ग्फ़िर लिल्लज़ीना ताबू वत्तबऊ सबीलका वकिहिं अज़ाबल जहीम",
      "hindi": "ऐ हमारे रब! तेरी रहमत और तेरा इल्म हर चीज़ पर छाया हुआ है। पस उन लोगों को बख्श दे जिन्होंने तौबा की और तेरे रास्ते की पैरवी की, और उन्हें जहन्नम की आग से बचा।",
      "reference": "Surah Ghafir (40:7)"
    },
    {
      "arabic": "رَبَّनَا وَأَدْخِلْهُمْ جَنَّاتِ عَدْنٍ الَّتِي وَعَدْتَهُمْ وَمَنْ صَلَحَ مِنْ آبَائِهِمْ وَأَزْوَاجِهِمْ وَذُرِّيَّاتِهِمْ ۚ إِنَّكَ أَنْتَ الْعَزِيزُ الْحَكِيمُ",
      "transliteration": "रब्बना व अदखिल्हुम जन्नाति अदनीनिल्लती वअत्तहुम व मन सलहा मिन आबाइहिम व अज़वाजिहिम व जुर्रिय्यातिहिम इन्नका अन्त़ल अज़ीज़ुल हकीम",
      "hindi": "ऐ हमारे रब! उन्हें हमेशा रहने वाली जन्नतों में दाखिल कर जिनका तूने उनसे वादा किया है, और उनके माँ-बाप, बीवियों और औलाद में से जो नेक हों उन्हें भी। बेशक तू ज़बरदस्त और हिकमत वाला है।",
      "reference": "Surah Ghafir (40:8)"
    },
    {
      "arabic": "رَبَّنَا اغْفِرْ لَنَا وَلِإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالْإِيمَانِ وَلَا تَجْعَلْ فِي قُلُوبِنَا غِلًّا لِلَّذِينَ آمَنُوا رَبَّनَا إِنَّكَ رَءُوفٌ رَحِيمٌ",
      "transliteration": "रब्बना-ग़फ़िर लना वलि इख्वानि नल लज़ीना सबकवूना बिल ईमानी वला तजअल फ़ी कुलूबिना गिल्लल लिल्लज़ीना आमनू रब्बना इन्नका रऊफुर रहीम",
      "hindi": "ऐ हमारे रब! हमें बख्श दे और हमारे उन भाइयों को भी जो हमसे पहले ईमान लाए, और ईमान वालों के लिए हमारे दिलों में कोई कीना (दुश्मनी) न रहने दे। ऐ हमारे रब! बेशक तू निहायत शफ़क़त (ममता) वाला और रहम करने वाला है।",
      "reference": "Surah Al-Hashr (59:10)"
    },
    {
      "arabic": "رَبَّنَا عَلَيْكَ تَوَكَّلْنَا وَإِلَيْके أَنَبْنَا وَإِلَيْكَ الْمَصِيرُ",
      "transliteration": "रब्बना अलैका तवक्कलना व इलैका अनब्ना व इलैकल मसीर",
      "hindi": "ऐ हमारे रब! हमने तुझ ही पर भरोसा किया, तेरी ही तरफ रुजू किया और तेरी ही तरफ लौट कर जाना है।",
      "reference": "Surah Al-Mumtahanah (60:4)"
    },
    {
      "arabic": "رَبَّنَا لَا تَجْعَلْنَا فِتْنَةً لِلَّذِينَ كَفَرُوا وَاغْفِرْ لَنَا رَبَّनَا ۖ إِنَّكَ أَنْتَ الْعَزِيزُ الْحَكِيمُ",
      "transliteration": "रब्बना ला तजअल्ना फ़ित्नातल लिल्लज़ीना कफ़रू वग्फिर लना रब्बना इन्नका अन्त़ल अज़ीज़ुल हकीम",
      "hindi": "ऐ हमारे रब! हमें काफिरों के लिए आज़माइश न बना और हमें बख्श दे। ऐ हमारे रब! बेशक तू ज़बरदस्त और हिकमत वाला है।",
      "reference": "Surah Al-Mumtahanah (60:5)"
    },
    {
      "arabic": "رَبَّنَا أَتْمِمْ لَنَا نُورَنَا وَاغْفِرْ لَنَا ۖ إِنَّكَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ",
      "transliteration": "रब्बना अत्म़िम लना नूरना वग्फिर लना इन्नका अला कुल्ली शैइन क़दीर",
      "hindi": "ऐ हमारे रब! हमारे लिए हमारा नूर पूरा कर दे और हमें बख्श दे। बेशक तू हर चीज़ पर कुदरत रखने वाला है।",
      "reference": "Surah At-Tahrim (66:8)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا فَاغْفِرْ لَنَا ذُنُوبَنَا وَقِنَا عَذَابَ النَّارِ",
      "transliteration": "रब्बना आमन्ना फग़फ़िर लना ज़ुनूबना व क़िना अज़ाबन्नार",
      "hindi": "ऐ हमारे रब! हम ईमान लाए, पस हमारे गुनाह बख्श दे और हमें आग (दोज़ख) के अज़ाब से बचा।",
      "reference": "Surah Ali 'Imran (3:16)"
    },
  ];

  static const List<Map<String, String>> bengaliDuas = [
    {
      "arabic": "رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنْتَ السَّمِيعُ الْعَلِيمُ",
      "transliteration": "রব্বানা তাক্বাব্বল মিন্না ইন্নাকা আন্তাস্ সামিউল আলিম",
      "bengali": "হে আমাদের রব! আমাদের পক্ষ থেকে (এটি) কবুল করুন; নিশ্চয়ই আপনি সর্বশ্রোতা, সর্বজ্ঞ।",
      "reference": "Surah Al-Baqarah (2:127)"
    },
    {
      "arabic": "رَبَّنَا وَاجْعَلْنَا مُسْلِمَيْنِ لَكَ وَمِنْ ذُرِّيَّتِنَا أُمَّةً مُسْلِمَةً لَكَ وَأَرِنَا مَنَاسِكَنَا وَتُبْ عَلَيْنَا إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ",
      "transliteration": "রব্বানা ওয়াজআলনা মুসলিমাইনি লাকা ওয়া মিন যুররিয়্যাতিনা উম্মাতাম মুসলিমাতাল লাকা ওয়া আরিনা মানাসিকানা ওয়া তুব আলাইনা ইন্নাকা আন্তাত তাওয়াবুর রাহিম",
      "bengali": "হে আমাদের রব! আমাদের উভয়কে আপনার একান্ত অনুগত (মুসলিম) করুন এবং আমাদের বংশধরদের মধ্য থেকেও আপনার এক অনুগত দল সৃষ্টি করুন; আমাদের ইবাদতের নিয়মসমূহ দেখিয়ে দিন এবং আমাদের তওবা কবুল করুন। নিশ্চয় আপনি তওবা কবুলকারী, পরম দয়ালু।",
      "reference": "Surah Al-Baqarah (2:128)"
    },
    {
      "arabic": "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
      "transliteration": "রব্বানা আতিনা ফিদ্দুনিয়া হাসানাতাওঁ ওয়া ফিল আখিরাতি হাসানাতাওঁ ওয়াক্বিনা আযাবান নার",
      "bengali": "হে আমাদের রব! আমাদের দুনিয়াতেও কল্যাণ দান করুন এবং আখেরাতেও কল্যাণ দান করুন এবং আমাদের জাহান্নামের আগুন থেকে রক্ষা করুন।",
      "reference": "Surah Al-Baqarah (2:201)"
    },
    {
      "arabic": "رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَثَبِّতْ أَقْدَامَنَا وَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ",
      "transliteration": "রব্বানা আফরিগ আলাইনা সাবরাওঁ ওয়া সাব্বিত আক্বদামানা ওয়ানসুরনা আলাল ক্বাওমিল কাফিরিন",
      "bengali": "হে আমাদের রব! আমাদের সবর (ধৈর্য) দান করুন, আমাদের পা দৃঢ় রাখুন এবং কাফের সম্প্রদায়ের বিরুদ্ধে আমাদের সাহায্য করুন।",
      "reference": "Surah Al-Baqarah (2:250)"
    },
    {
      "arabic": "رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا",
      "transliteration": "রব্বানা লা তুআখিজনা ইন নাসিনা আও আখতানা",
      "bengali": "হে আমাদের রব! যদি আমরা ভুলে যাই কিংবা ভুল করি, তবে আমাদের অপরাধী করবেন না।",
      "reference": "Surah Al-Baqarah (2:286)"
    },
    {
      "arabic": "رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا",
      "transliteration": "রব্বানা ওয়া লা তাহমিল আলাইনা ইসরান কামা হামালতাহু আলাল্লাযিনা মিন ক্বাবলিনা",
      "bengali": "হে আমাদের রব! আমাদের ওপর এমন বোঝা চাপিয়ে দেবেন না, যা আমাদের পূর্ববর্তীদের ওপর চাপিয়ে দিয়েছিলেন।",
      "reference": "Surah Al-Baqarah (2:286)"
    },
    {
      "arabic": "رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ",
      "transliteration": "রব্বানা ওয়া লা তুহাম্মিলনা মা লা তাক্বাতা লানা বিহি ওয়াফু আন্না ওয়াগফির লানা ওয়ারহামনা আন্তা মাওলানা ফানসুরনা আলাল ক্বাওমিল কাফিরিন",
      "bengali": "হে আমাদের রব! আমাদের ওপর এমন বোঝা চাপাবেন না যা বহন করার ক্ষমতা আমাদের নেই। আমাদের পাপ মোচন করুন, আমাদের ক্ষমা করুন এবং আমাদের ওপর দয়া করুন। আপনিই আমাদের অভিভাবক; সুতরাং কাফের সম্প্রদায়ের বিরুদ্ধে আমাদের জয়যুক্ত করুন।",
      "reference": "Surah Al-Baqarah (2:286)"
    },
    {
      "arabic": "رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً ۚ إِنَّكَ أَنْتَ الْوَهَّابُ",
      "transliteration": "রব্বানা লা তুযিগ কুলুবানা বা'দা ইয হাদাইতানা ওয়া হাব লানা মিল্লাদুনকা রাহমাহ ইন্নাকা আন্তাল ওয়াহ্হাব",
      "bengali": "হে আমাদের রব! আমাদের হেদায়েত দান করার পর আমাদের অন্তরকে সত্যপথ থেকে বিচ্যুত করবেন না এবং আপনার পক্ষ থেকে আমাদের রহমত দান করুন। নিশ্চয় আপনি পরম দাতা।",
      "reference": "Surah Ali 'Imran (3:8)"
    },
    {
      "arabic": "رَبَّنَا إِنَّكَ جَامِعُ النَّاسِ لِيَوْمٍ لَا رَيْبَ فِيهِ ۚ إِنَّ اللَّهَ لَا يُخْلِفُ الْمِيعَادَ",
      "transliteration": "রব্বানা ইন্নাকা জামিউন নাসি লি-ইয়াওমিল লা রাইবা ফিহি ইন্নাল্লাহা লা ইউখলিফুল মিআদ",
      "bengali": "হে আমাদের রব! আপনি অবশ্যই মানবজাতিকে একদিন একত্রিত করবেন যে দিনে কোনো সন্দেহ নেই; নিশ্চয় আল্লাহ তাঁর ওয়াদা খেলাফ করেন না।",
      "reference": "Surah Ali 'Imran (3:9)"
    },
    {
      "arabic": "رَبَّنَا إِنَّنَا آمَنَّا فَاغْفِرْ لَنَا ذُنُوبَنَا وَقِنَا عَذَابَ النَّارِ",
      "transliteration": "রব্বানা ইন্নানা আমান্না ফাগফির লানা যুনুবানা ওয়াক্বিনা আযাবান নার",
      "bengali": "হে আমাদের রব! আমরা ঈমান এনেছি, সুতরাং আমাদের গুনাহসমূহ ক্ষমা করে দিন এবং আমাদের জাহান্নামের আগুন থেকে রক্ষা করুন।",
      "reference": "Surah Ali 'Imran (3:16)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا بِمَا أَنْزَلْتَ وَاتَّبَعْنَا الرَّسُولَ فَاكْتُبْنَا مَعَ الشَّاهِدِينَ",
      "transliteration": "রব্বানা আমান্না বিমা আনযালতা ওয়াত্তাবানার রাসূলা ফাক্তুবনা মাআশ শাহিদিন",
      "bengali": "হে আমাদের রব! আপনি যা নাযিল করেছেন তার ওপর আমরা ঈমান এনেছি এবং আমরা রাসূলের আনুগত্য কবুল করেছি। সুতরাং আমাদের সাক্ষ্যদানকারীদের তালিকাভুক্ত করুন।",
      "reference": "Surah Ali 'Imran (3:53)"
    },
    {
      "arabic": "رَبَّنَا اغْفِرْ لَنَا ذُنُوبَنَا وَإِسْرَافَنَا فِي أَمْرِنَا وَثَبِّتْ أَقْدَامَنَا وَانْصُرْنَا عَلَى الْقَوْমِ الْكَافِرِينَ",
      "transliteration": "রব্বানাগফির লানা যুনুবানা ওয়া ইসরাফানা ফি আমরিণা ওয়া সাব্বিত আক্বদামানা ওয়ানসুরনা আলাল ক্বাওমিল কাফিরিন",
      "bengali": "হে আমাদের রব! আমাদের গুনাহসমূহ এবং আমাদের কাজে যা সীমালঙ্ঘন হয়েছে তা ক্ষমা করুন, আমাদের পা দৃঢ় রাখুন এবং কাফেরদের বিরুদ্ধে আমাদের সাহায্য করুন।",
      "reference": "Surah Ali 'Imran (3:147)"
    },
    {
      "arabic": "رَبَّنَا مَا خَلَقْتَ هَٰذَا بَاطِلًا سُبْحَانَكَ فَقِنَا عَذَابَ النَّارِ",
      "transliteration": "রব্বানা মা খালাক্বতা হাযা বাতিলান সুবহানাকা ফাক্বিনা আযাবান নার",
      "bengali": "হে আমাদের রব! আপনি এসব নিরর্থক সৃষ্টি করেননি। আপনি অতি পবিত্র! সুতরাং আমাদের জাহান্নামের আযাব থেকে রক্ষা করুন।",
      "reference": "Surah Ali 'Imran (3:191)"
    },
    {
      "arabic": "رَبَّنَا إِنَّكَ مَنْ تُدْخِلِ النَّارَ فَقَدْ أَخْزَيْتَهُ ۖ وَمَا لِلظَّالِمِينَ مِنْ أَنْصَارٍ",
      "transliteration": "রব্বানা ইন্নাকা মান তুদখিলিন নারা ফাক্বাদ আখযাইতাহু ওয়া মা লিযযালিমিনা মিন আনসার",
      "bengali": "হে আমাদের রব! আপনি যাকে জাহান্নামে নিক্ষেপ করবেন তাকে নিশ্চয়ই অপমানিত করবেন; আর জালেমদের জন্য কোনো সাহায্যকারী নেই।",
      "reference": "Surah Ali 'Imran (3:192)"
    },
    {
      "arabic": "رَبَّنَا إِنَّنَا سَمِعْنَا مُنَادِيًا يُنَادِي لِلْإِيمَانِ أَنْ آمِنُوا بِرَبِّكُمْ فَآمَنَّا",
      "transliteration": "রব্বানা ইন্নানা সামিনা মুনাদিয়ান ইউনাদি লিল-ঈমানি আন আমিনু বিরাব্বিকুম ফা-আমান্না",
      "bengali": "হে আমাদের রব! আমরা একজন আহ্বানকারীকে ঈমানের দিকে আহ্বান করতে শুনেছি যে— 'তোমাদের রবের প্রতি ঈমান আনো', তাই আমরা ঈমান এনেছি।",
      "reference": "Surah Ali 'Imran (3:193)"
    },
    {
      "arabic": "رَبَّنَا فَاغْفِرْ لَنَا ذُنُوبَنَا وَكَفِّرْ عَنَّا سَيِّئَاتِنَا وَتَوَفَّنَا مَعَ الْأَبْرَارِ",
      "transliteration": "রব্বানা ফাগফির লানা যুনুবানা ওয়া কাফফির আন্না সাইয়িআতিনা ওয়া তাওয়াফ্ফানা মাআল আবরার",
      "bengali": "হে আমাদের রব! আমাদের গুনাহসমূহ ক্ষমা করুন, আমাদের ত্ৰুটিগুলো মোচন করুন এবং আমাদের নেককারদের সঙ্গে মৃত্যু দান করুন।",
      "reference": "Surah Ali 'Imran (3:193)"
    },
    {
      "arabic": "رَبَّنَا وَآتِنَا مَا وَعَدْتَنَا عَلَىٰ رُسُلِكَ وَلَا تُخْزِنَا يَوْমَ الْقِيَامَةِ ۗ إِنَّكَ لَا تُخْلِفُ الْمِيعَادَ",
      "transliteration": "রব্বানা ওয়া আতিনা মা ওয়াদতানা আলা রুসুলিকা ওয়া লা তুখযিনা ইয়াওমাল ক্বিয়ামাহ ইন্নাকা লা তুখলিফুল মিআদ",
      "bengali": "হে আমাদের রব! আপনার রাসূলদের মাধ্যমে আমাদের যা ওয়াদা করেছেন তা দান করুন এবং কেয়ামতের দিন আমাদের অপমানিত করবেন না। নিশ্চয় আপনি ওয়াদা ভঙ্গ করেন না।",
      "reference": "Surah Ali 'Imran (3:194)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا فَاكْتُبْنَا مَعَ الشَّاهِدِينَ",
      "transliteration": "রব্বানা আমান্না ফাক্তুবনা মাআশ শাহিদিন",
      "bengali": "হে আমাদের রব! আমরা ঈমান এনেছি, সুতরাং আমাদের সাক্ষ্যদানকারীদের অন্তর্ভুক্ত করুন।",
      "reference": "Surah Al-Ma'idah (5:83)"
    },
    {
      "arabic": "رَبَّنَا أَنْزِلْ عَلَيْنَا مَائِدَةً مِنَ السَّمَاءِ تَكُونُ لَنَا عِيدًا لِأَوَّلِنَا وَآخِرِنَا وَآيَةً مِنْكَ ۖ وَارْজُقْنَا وَأَنْتَ خَيْرُ الرَّازِقِينَ",
      "transliteration": "রব্বানা আনযিল আলাইনা মাইদাতাম মিনাছ সামাই তাকুনু লানা ঈদাল্লি আউয়ালিনা ওয়া আখিরিনা ওয়া আয়াতাম মিনকা ওয়ারযুক্বনা ওয়া আন্তা খাইরুর রাযিক্বিন",
      "bengali": "হে আমাদের রব! আমাদের জন্য আসমান থেকে খাদ্যভর্তি দস্তরখান নাযিল করুন যা আমাদের আদি-অন্ত সবার জন্য আনন্দোৎসব হবে এবং আপনার পক্ষ থেকে একটি নিদর্শন হবে। আমাদের রিযিক দান করুন, আপনিই শ্রেষ্ঠ রিযিকদাতা।",
      "reference": "Surah Al-Ma'idah (5:114)"
    },
    {
      "arabic": "رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ",
      "transliteration": "রব্বানা যালামনা আনফুসানা ওয়া ইল্লাম তাগফির লানা ওয়া তারহামনা লানাকুনান্না মিনাল খাসিরিন",
      "bengali": "হে আমাদের রব! আমরা নিজেদের ওপর জুলুম করেছি। যদি আপনি আমাদের ক্ষমা না করেন এবং দয়া না করেন, তবে অবশ্যই আমরা ক্ষতিগ্রস্তদের অন্তর্ভুক্ত হবো।",
      "reference": "Surah Al-A'raf (7:23)"
    },
    {
      "arabic": "رَبَّنَا لَا تَجْعَلْنَا مَعَ الْقَوْمِ الظَّالِمِينَ",
      "transliteration": "রব্বানা লা তাজআলনা মাআল ক্বাওমিয যালিমিন",
      "bengali": "হে আমাদের রব! আমাদের জালেম সম্প্রদায়ের সঙ্গী করবেন না।",
      "reference": "Surah Al-A'raf (7:47)"
    },
    {
      "arabic": "رَبَّنَا افْتَحْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنْتَ خَيْرُ الْفَاتِحِينَ",
      "transliteration": "রব্বানাফতাহ বাইনানা ওয়া বাইনা ক্বাওমিনা বিল হাক্কি ওয়া আন্তা খাইরুল ফাতিহিন",
      "bengali": "হে আমাদের রব! আমাদের ও আমাদের সম্প্রদায়ের মধ্যে ন্যায়ের সাথে ফয়সালা করে দিন, আপনিই শ্রেষ্ঠ ফয়সালাকারী।",
      "reference": "Surah Al-A'raf (7:89)"
    },
    {
      "arabic": "رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَتَوَفَّنَا مُسْلِمِينَ",
      "transliteration": "রব্বানা আফরিগ আলাইনা সাবরাওঁ ওয়া তাওয়াফ্ফানা মুসলিমিন",
      "bengali": "হে আমাদের রব! আমাদের পূর্ণ ধৈর্য দান করুন এবং মুসলিম হিসেবে আমাদের মৃত্যু দান করুন।",
      "reference": "Surah Al-A'raf (7:126)"
    },
    {
      "arabic": "رَبَّنَا لَا تَجْعَلْنَا فِتْنَةً لِلْقَوْمِ الظَّالِمِينَ وَنَجِّنَا بِرَحْمَتِكَ مِنَ الْقَوْমِ الْكَافِرِينَ",
      "transliteration": "রব্বানা লা তাজআলনা ফিত্নাতাল লিল-ক্বাওমিয যালিমিন ওয়া নাজ্জিনা বিরাহমাতিকা মিনাল ক্বাওমিল কাফিরিন",
      "bengali": "হে আমাদের রব! আমাদের জালেমদের পরীক্ষার পাত্র করবেন না; এবং আপনার অনুগ্রহে আমাদের কাফের সম্প্রদায় থেকে রক্ষা করুন।",
      "reference": "Surah Yunus (10:85-86)"
    },
    {
      "arabic": "رَبَّنَا إِنَّكَ تَعْلَمُ مَا نُخْفِي وَمَا نُعْلِنُ ۗ وَمَا يَخْفَىٰ عَلَى اللَّهِ مِنْ شَيْءٍ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ",
      "transliteration": "রব্বানা ইন্নাকা তালামু মা নুখফি ওয়া মা নুলিনু ওয়া মা ইয়াখফা আলাল্লাহি মিন শাইয়িন ফিল আরযি ওয়ালা ফিস সামাই",
      "bengali": "হে আমাদের রব! নিশ্চয় আপনি জানেন যা আমরা গোপন করি এবং যা আমরা প্রকাশ করি। আসমান ও জমিনের কোনো কিছুই আল্লাহর কাছে গোপন থাকে না।",
      "reference": "Surah Ibrahim (14:38)"
    },
    {
      "arabic": "رَبَّنَا وَتَقَبَّلْ دُعَاءِ",
      "transliteration": "রব্বানা ওয়া তাক্বাব্বল দুআ",
      "bengali": "হে আমাদের রব! আমার প্রার্থনা কবুল করুন।",
      "reference": "Surah Ibrahim (14:40)"
    },
    {
      "arabic": "رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ",
      "transliteration": "রব্বানাগফির লি ওয়ালি-ওয়ালিদাইয়্যা ওয়ালিল মুমিনিনা ইয়াওমা ইয়াক্বুমুল হিসাব",
      "bengali": "হে আমাদের রব! বিচারের দিন আমাকে, আমার পিতা-মাতাকে এবং সব মুমিনকে ক্ষমা করে দিন।",
      "reference": "Surah Ibrahim (14:41)"
    },
    {
      "arabic": "رَبَّنَا آتِنَا مِنْ لَدُنْكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا",
      "transliteration": "রব্বানা আতিনা মিল্লাদুনকা রহমাতাওঁ ওয়া হাইয়্যি লানা মিন আমরিণা রাশাদা",
      "bengali": "হে আমাদের রব! আপনার পক্ষ থেকে আমাদের রহমত দান করুন এবং আমাদের কার্যাবলি সঠিকভাবে পরিচালনার ব্যবস্থা করুন।",
      "reference": "Surah Al-Kahf (18:10)"
    },
    {
      "arabic": "رَبَّنَا إِنَّنَا نَখָافُ أَنْ يَفْرُطَ عَلَيْنَا أَوْ أَنْ يَطْغَىٰ",
      "transliteration": "রব্বানা ইন্নানা নাখাফু আই ইয়াফরুতা আলাইনা আও আই ইয়াতগা",
      "bengali": "হে আমাদের রব! আমরা আশঙ্কা করছি যে সে আমাদের ওপর জুলুম করবে কিংবা বিদ্রোহ করবে।",
      "reference": "Surah Ta-Ha (20:45)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا فَاغْفِرْ لَنَا وَارْحَمْنَا وَأَنْتَ خَيْرُ الرَّاحِمِينَ",
      "transliteration": "রব্বানা আমান্না ফাগফির লানা ওয়ারহামনা ওয়া আন্তা খাইরুর রাহিমিন",
      "bengali": "হে আমাদের রব! আমরা ঈমান এনেছি, সুতরাং আমাদের ক্ষমা করুন এবং আমাদের ওপর দয়া করুন; আপনিই তো সর্বশ্রেষ্ঠ দয়ালু।",
      "reference": "Surah Al-Mu'minun (23:109)"
    },
    {
      "arabic": "رَبَّنَا اصْرِفْ عَنَّا عَذَابَ جَهَنَّمَ ۖ إِنَّ عَذَابَهَا كَانَ غَرَامًا",
      "transliteration": "রব্বানাস রিফ আন্না আযাবা জাহান্নামা ইন্না আযাবাহা কানা গারামা",
      "bengali": "হে আমাদের রব! আমাদের থেকে জাহান্নামের আযাব সরিয়ে নিন। নিশ্চয় এর আযাব অত্যন্ত যন্ত্রণাদায়ক।",
      "reference": "Surah Al-Furqan (25:65)"
    },
    {
      "arabic": "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا",
      "transliteration": "রব্বানা হাব লানা মিন আযওয়াজিনা ওয়া যুররিয়্যাতিনা ক্বুররাতা আইয়ুনি ওয়াজআলনা লিল মুত্তাক্বিনা ইমামা",
      "bengali": "হে আমাদের রব! আমাদের জন্য এমন স্ত্রী ও সন্তান দান করুন যারা আমাদের চক্ষু শীতল করবে এবং আমাদের মুত্তাকীদের ইমাম বানিয়ে দিন।",
      "reference": "Surah Al-Furqan (25:74)"
    },
    {
      "arabic": "رَبَّنَا لَغَفُورٌ شَكُورٌ",
      "transliteration": "রব্বানা লাগাফুরুন শাকুর",
      "bengali": "আমাদের রব তো অবশ্যই ক্ষমাশীল, গুণগ্রাহী।",
      "reference": "Surah Fatir (35:34)"
    },
    {
      "arabic": "رَبَّنَا وَسِعْتَ كُلَّ شَيْءٍ رَحْمَةً وَعِلْمًا فَاغْفِرْ لِلَّذِينَ تَابُوا وَاتَّبَعُوا سَبِيلَكَ وَقِهِمْ عَذَابَ الْجَحِيمِ",
      "transliteration": "রব্বানা ওয়াসিআতা কুল্লা শাইয়ি রহমাতাওঁ ওয়া ইলমান ফাগফির লিল্লাযিনা তাবু ওয়াত্তাবাউ সাবিলকা ওয়াক্বিহিম আযাবাল জাহিম",
      "bengali": "হে আমাদের রব! আপনার রহমত ও জ্ঞান প্রতিটি বস্তুকে পরিবেষ্টন করে আছে। সুতরাং যারা তওবা করেছে এবং আপনার পথ অনুসরণ করেছে তাদের ক্ষমা করুন এবং জাহান্নামের আগুন থেকে রক্ষা করুন।",
      "reference": "Surah Ghafir (40:7)"
    },
    {
      "arabic": "رَبَّنَا وَأَدْخِلْهُمْ جَنَّاتِ عَدْنٍ الَّتِي وَعَدْتَهُمْ وَمَنْ صَلَحَ مِنْ آبَائِهِمْ وَأَزْوَاجِهِمْ وَذُرِّيَّاتِهِمْ ۚ إِنَّكَ أَنْتَ الْعَزِيزُ الْحَكِيمُ",
      "transliteration": "রব্বানা ওয়া আদখিলহুম জান্নাতি আদনিনিল্লাতি ওয়াদতাহুম ওয়া মান সালাহা মিন আবাইহিম ওয়া আযওয়াজিহিম ওয়া যুররিয়্যাতিহিম ইন্নাকা আন্তাল আযিযুল হাকিম",
      "bengali": "হে আমাদের রব! আপনি তাদের স্থায়ী জান্নাতে প্রবেশ করান যার ওয়াদা আপনি তাদের দিয়েছেন; আর তাদের পিতৃপুরুষ, স্ত্রী ও সন্তানদের মধ্যে যারা নেককার তাদেরও। নিশ্চয় আপনি পরাক্রমশালী, প্রজ্ঞাময়।",
      "reference": "Surah Ghafir (40:8)"
    },
    {
      "arabic": "رَبَّنَا اغْفِرْ لَنَا وَلِإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالْإِيمَانِ وَلَا تَجْعَلْ فِي قُلُوبِنَا غِلًّا لِلَّذِينَ آمَنُوا رَبَّنَا إِنَّكَ رَءُوفٌ رَحِيمٌ",
      "transliteration": "রব্বানাগফির লানা ওয়া লি-ইখওয়ানিনাল্লাযিনা সাবাক্বুনা বিল-ঈমানি ওয়া লা তাজআল ফি কুলুবিনা গিল্লাল লিল্লাযিনা আমানু রব্বানা ইন্নাকা রাউফুর রাহিম",
      "bengali": "হে আমাদের রব! আমাদের এবং আমাদের সেই ভাইদের ক্ষমা করুন যারা আমাদের আগে ঈমান এনেছে এবং মুমিনদের বিরুদ্ধে আমাদের অন্তরে কোনো বিদ্বেষ রাখবেন না। হে আমাদের রব! নিশ্চয় আপনি অতি দয়ারু, পরম দয়ালু।",
      "reference": "Surah Al-Hashr (59:10)"
    },
    {
      "arabic": "رَبَّنَا عَلَيْكَ تَوَكَّلْنَا وَإِلَيْكَ أَنَبْنَا وَإِلَيْكَ الْمَصِيرُ",
      "transliteration": "রব্বানা আলাইকা তাওয়াক্কালনা ওয়া ইলাইকা আনাবনা ওয়া ইলাইকাল মাসীর",
      "bengali": "হে আমাদের রব! আমরা কেবল আপনার ওপরই ভরসা করেছি, আপনার দিকেই প্রত্যাবর্তন করেছি এবং আপনার কাছেই আমাদের শেষ গন্তব্য।",
      "reference": "Surah Al-Mumtahanah (60:4)"
    },
    {
      "arabic": "رَبَّنَا لَا تَجْعَلْنَا فِتْنَةً لِلَّذِينَ كَفَرُوا وَاغْفِرْ لَنَا رَبَّنَا ۖ إِنَّكَ أَنْتَ الْعَزِيزُ الْحَكِيمُ",
      "transliteration": "রব্বানা লা তাজআলনা ফিত্নাতাল লিল্লাযিনা কাফারু ওয়াগফির লানা রব্বানা ইন্নাকা আন্তাল আযিযুল হাকিম",
      "bengali": "হে আমাদের রব! আমাদের কাফেরদের পরীক্ষার পাত্র করবেন না এবং আমাদের ক্ষমা করুন। হে আমাদের রব! নিশ্চয় আপনি পরাক্রমশালী, প্রজ্ঞাময়।",
      "reference": "Surah Al-Mumtahanah (60:5)"
    },
    {
      "arabic": "رَبَّنَا أَتْمِمْ لানা নূরাণা ওয়াসফফির লানা ইন্নাকা আল কুল্লি শাইয়িন ক্বাদ্বীৰ",
      "transliteration": "রব্বানা আতমিম লানা নূরানা ওয়াগফির লানা ইন্নাকা আলা কুল্লি শাইয়িন ক্বাদীর",
      "bengali": "হে আমাদের রব! আমাদের জন্য আমাদের নূর (জ্যোতি) পূর্ণ করে দিন এবং আমাদের ক্ষমা করুন। নিশ্চয় আপনি সবকিছুর ওপর ক্ষমতাবান।",
      "reference": "Surah At-Tahrim (66:8)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا فَاغْفِرْ لَنَا ذُنُوبَنَا وَقِنَا عَذَابَ النَّارِ",
      "transliteration": "রব্বানা আমান্না ফাগফির লানা যুনুবানা ওয়াক্বিনা আযাবান নার",
      "bengali": "হে আমাদের রব! আমরা ঈমান এনেছি, সুতরাং আমাদের গুনাহসমূহ ক্ষমা করে দিন এবং আমাদের জাহান্নামের আগুন থেকে রক্ষা করুন।",
      "reference": "Surah Ali 'Imran (3:16)"
    },
  ];

  static const List<Map<String, String>> assameseDuas = [
    {
      "arabic": "رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنْتَ السَّمِيعُ الْعَلِيمُ",
      "transliteration": "ৰব্বানা তাক্বাব্বল মিন্না ইন্নাকা আন্তাস্ সমীউল আলীম",
      "assamese": "হে আমাৰ ৰব! আমাৰ ফালৰ পৰা (এই সেৱা) কবুল কৰক; নিশ্চয় আপুনি সৰ্বশ্ৰোতা, সৰ্বজ্ঞ।",
      "reference": "Surah Al-Baqarah (2:127)"
    },
    {
      "arabic": "رَبَّنَا وَاجْعَلْنَا مُسْلِمَيْنِ لَكَ وَمِنْ ذُرِّيَّتِنَا أُمَّةً مُسْلِمَةً لَكَ وَأَرِنَا مَنَاسِكَنَا وَتُبْ عَلَيْنَا إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ",
      "transliteration": "ৰব্বানা ওয়াজআলনা মুছ্লিমাইনি লাকা ওয়া মিন যুৰৰিয়্যাতিনা উম্মাতাম মুছ্লিমাতাল লাকা ওয়া আৰিনা মানাছিকানা ওয়া তুব আলাইনা ইন্নাকা আন্তাত তাওয়াবাৰ ৰাহীম",
      "assamese": "হে আমাৰ ৰব! আমাক আপোনাৰ প্ৰতি অনুগত (মুছলিম) বনাওক আৰু আমাৰ বংশধৰৰ মাজৰ পৰাও এটা দলক আপোনাৰ অনুগত কৰক; আমাক আমাৰ ইবাদতৰ নিয়মবোৰ দেখুৱাই দিয়ক আৰু আমাৰ তওবা কবুল কৰক। নিশ্চয় আপুনি তওবা কবুলকাৰী, পৰম দয়ালু।",
      "reference": "Surah Al-Baqarah (2:128)"
    },
    {
      "arabic": "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
      "transliteration": "ৰব্বানা আতিনা ফিদ্দুনিয়া হাছানাতাওঁ ওয়া ফিল আখিৰাতি হাছানাতাওঁ ওয়াক্বিনা আযাবান নাৰ",
      "assamese": "হে আমাৰ ৰব! আমাক পৃথিৱীত কল্যাণ দান কৰক আৰু আখেৰাততো কল্যাণ দান কৰক, আৰু আমাক জাহান্নামৰ জুইৰ পৰা ৰক্ষা কৰক।",
      "reference": "Surah Al-Baqarah (2:201)"
    },
    {
      "arabic": "رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَثَبِّتْ أَقْدَامَنَا وَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ",
      "transliteration": "ৰব্বানা আফৰিগ আলাইনা ছাবৰাওঁ ওয়া ছাব্বিত আক্বদামানা ওয়ানছুৰনা আলাল ক্বাওমিল কাফিৰীন",
      "assamese": "হে আমাৰ ৰব! আমাক ধৈৰ্য্য দান কৰক, আমাৰ ভৰি স্থিৰ ৰাখক আৰু কাফিৰ সম্প্ৰদায়ৰ বিৰুদ্ধে আমাক সহায় কৰক।",
      "reference": "Surah Al-Baqarah (2:250)"
    },
    {
      "arabic": "رَبَّنَا لَا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا",
      "transliteration": "ৰব্বানা লা তুআখিজনা ইন নাছিনা আও আখতানা",
      "assamese": "হে আমাৰ ৰব! যদি আমি পাহৰি যাওঁ বা ভুল কৰোঁ, তেন্তে আমাক অপৰাধী নকৰিব।",
      "reference": "Surah Al-Baqarah (2:286)"
    },
    {
      "arabic": "رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا",
      "transliteration": "ৰব্বানা ওয়া লা তাহমিল আলাইনা ইছৰান কামা হামালতাহু আলাল্লাযিনা মিন ক্বাবলিনা",
      "assamese": "হে আমাৰ ৰব! আমাৰ ওপৰত এনেকুৱা বোজা নিদিব যিটো আমাৰ আগৰ লোকসকলৰ ওপৰত দিছিল।",
      "reference": "Surah Al-Baqarah (2:286)"
    },
    {
      "arabic": "رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنْتَ مَوْلَانَا فَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ",
      "transliteration": "ৰব্বানা ওয়া লা তুহাম্মিলনা মা লা তাক্বাতা লানা বিহি ওয়াফু আন্না ওয়াগফিৰ লানা ওয়াৰহামনা আন্তা মাওলানা ফানছুৰনা আলাল ক্বাওমিল কাফিৰীন",
      "assamese": "হে আমাৰ ৰব! আমাক এনে বোজা নিদিব যিটো বহন কৰাৰ শক্তি আমাৰ নাই। আমাৰ পাপবোৰ মচি পেলাওক, আমাক ক্ষমা কৰক আৰু আমাৰ ওপৰত দয়া কৰক। আপুনিয়েই আমাৰ অভিভাৱক; গতিকে কাফিৰ সম্প্ৰদায়ৰ বিৰুদ্ধে আমাক সহায় কৰক।",
      "reference": "Surah Al-Baqarah (2:286)"
    },
    {
      "arabic": "رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً ۚ إِنَّكَ أَنْتَ الْوَهَّابُ",
      "transliteration": "ৰব্বানা লা তুযিগ কুলুবানা বাদা ইয হাদাইতানা ওয়া হাব লানা মিল্লাদুনকা ৰাহমাহ ইন্নাকা আন্তাল ওয়াহ্হাব",
      "assamese": "হে আমাৰ ৰব! আমাক হেদায়েত দিয়াৰ পিছত আমাৰ অন্তৰক বিপথে নিদিব আৰু আপোনাৰ ফালৰ পৰা আমাক ৰহমত দান কৰক। নিশ্চয় আপুনি মহা দাতা।",
      "reference": "Surah Ali 'Imran (3:8)"
    },
    {
      "arabic": "رَبَّنَا إِنَّكَ جَامِعُ النَّاسِ لِيَوْمٍ لَا رَيْبَ فِيهِ ۚ إِنَّ اللَّهَ لَا يُخْلِفُ الْمِيعَادَ",
      "transliteration": "ৰব্বানা ইন্নাকা জামিউন নাছি লি-ইয়াওমিল লা ৰাইবা ফিহি ইন্নাল্লাহা লা ইউখলিফুল মীআদ",
      "assamese": "হে আমাৰ ৰব! আপুনি মানুহক এনে এটা দিনত একত্ৰিত কৰিব যিটো দিনৰ আগমনত কোনো সন্দেহ নাই; নিশ্চয় আল্লাহে তেওঁৰ প্ৰতিশ্ৰুতিৰ লৰচৰ নকৰে।",
      "reference": "Surah Ali 'Imran (3:9)"
    },
    {
      "arabic": "رَبَّنَا إِنَّنَا آمَنَّا فَاغْفِرْ لَنَا ذُنُوبَنَا وَقِنَا عَذَابَ النَّارِ",
      "transliteration": "ৰব্বানা ইন্নানা আমান্না ফাগফিৰ লানা যুনুবানা ওয়াক্বিনা আযাবান নাৰ",
      "assamese": "হে আমাৰ ৰব! আমি ঈমান আনিছোঁ, গতিকে আমাৰ পাপবোৰ ক্ষমা কৰক আৰু আমাক জুইৰ শাস্তিৰ পৰা ৰক্ষা কৰক।",
      "reference": "Surah Ali 'Imran (3:16)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا بِمَا أَنْزَلْتَ وَاتَّبَعْنَا الرَّسُولَ فَاكْتُبْنَا مَعَ الشَّاهِدِينَ",
      "transliteration": "ৰব্বানা আমান্না বিমা আনযালতা ওয়াত্তাবানাৰ ৰাছুলা ফাক্তুবনা মাআশ শাহিদীন",
      "assamese": "হে আমাৰ ৰব! আপুনি যি নাজিল কৰিছে তাৰ ওপৰত আমি ঈমান আনিছোঁ আৰু আমি ৰাছুলৰ অনুসৰণ কৰিছোঁ। গতিকে আমাক সাক্ষীসকলৰ তালিকাত অন্তৰ্ভুক্ত কৰক।",
      "reference": "Surah Ali 'Imran (3:53)"
    },
    {
      "arabic": "رَبَّنَا اغْفِرْ لَنَا ذُنُوبَنَا وَإِسْرَافَنَا فِي أَمْرِنَا وَثَبِّتْ أَقْدَامَنَا وَانْصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ",
      "transliteration": "ৰব্বানাগফিৰ লানা যুনুবানা ওয়া ইছৰাফানা ফি আমৰিনা ওয়া ছাব্বিত আক্বদামানা ওয়ানছুৰনা আলাল ক্বাওমিল কাফিৰীন",
      "assamese": "হে আমাৰ ৰব! আমাৰ পাপবোৰ আৰু আমাৰ কাম-কাজত হোৱা সীমালংঘনবোৰ ক্ষমা কৰক, আমাৰ ভৰি স্থিৰ ৰাখক আৰু কাফিৰসকলৰ বিৰুদ্ধে আমাক জয়ী কৰক।",
      "reference": "Surah Ali 'Imran (3:147)"
    },
    {
      "arabic": "رَبَّنَا مَا خَلَقْتَ هَٰذَا بَاطِلًا سُبْحَانَكَ فَقِنَا عَذَابَ النَّارِ",
      "transliteration": "ৰব্বানা মা খালাক্বতা হাযা বাতিলান ছুবহানাকা ফাক্বিনা আযাবান নাৰ",
      "assamese": "হে আমাৰ ৰব! আপুনি এইবোৰ উদ্দেশ্যহীনভাৱে সৃষ্টি কৰা নাই। আপুনি অতি পবিত্ৰ! গতিকে আমাক জুইৰ শাস্তিৰ পৰা ৰক্ষা কৰক।",
      "reference": "Surah Ali 'Imran (3:191)"
    },
    {
      "arabic": "رَبَّنَا إِنَّكَ مَنْ تُدْخِلِ النَّارَ فَقَدْ أَخْزَيْتَهُ ۖ وَمَا لِلظَّالِمِينَ مِنْ أَنْصَارٍ",
      "transliteration": "ৰব্বানা ইন্নাকা মান তুদখিলিন নাৰা ফাক্বাদ আখযাইতাহু ওয়া মা লিযযালিমিনা মিন আনছাৰ",
      "assamese": "হে আমাৰ ৰব! আপুনি যাক জুইত নিক্ষেপ কৰিব তাক নিশ্চয় অপমানিত কৰিব; আৰু অন্যায়কাৰীসকলৰ বাবে কোনো সহায়কাৰী নাই।",
      "reference": "Surah Ali 'Imran (3:192)"
    },
    {
      "arabic": "رَبَّنَا إِنَّنَا سَمِعْنَا مُنَادِيًا يُنَادِي لِلْإِيمَانِ أَنْ آمِنُوا بِرَبِّكُمْ فَآمَنَّا",
      "transliteration": "ৰব্বানা ইন্নানা ছামিনা মুনাদিয়ান ইউনাদি লিল-ঈমানি আন আমিনু বিৰব্বিকুম ফ-আমান্না",
      "assamese": "হে আমাৰ ৰব! আমি এজন আহ্বানকাৰীক ঈমানৰ ফালে মাতি থকা শুনিলোঁ যে— 'তোমালোকৰ ৰবৰ ওপৰত ঈমান আনা', গতিকে আমি ঈমান আনিছোঁ।",
      "reference": "Surah Ali 'Imran (3:193)"
    },
    {
      "arabic": "رَبَّنَا فَاغْفِرْ لَنَا ذُنُوبَنَا وَكَفِّرْ عَنَّا سَيِّئَاتِنَا وَتَوَفَّنَا مَعَ الْأَبْرَارِ",
      "transliteration": "ৰব্বানা ফাগফিৰ লানা যুনুবানা ওয়া কাফিৰ আন্না ছাইয়িআতিনা ওয়া তাওয়াফ্ফানা মাআল আবৰাৰ",
      "assamese": "হে আমাৰ ৰব! আমাৰ পাপবোৰ ক্ষমা কৰক, আমাৰ ত্ৰুটিবোৰ মচি দিয়ক আৰু আমাক নেক লোকসকলৰ সৈতে মৃত্যু দান কৰক।",
      "reference": "Surah Ali 'Imran (3:193)"
    },
    {
      "arabic": "رَبَّنَا وَآتِنَا مَا وَعَدْتَنَا عَلَىٰ رُسُلِكَ وَلَا تُخْزِنَا يَوْمَ الْقِيَامَةِ ۗ إِنَّكَ لَا تُخْلِفُ الْمِيعَادَ",
      "transliteration": "ৰব্বানা ওয়া আতিনা মা ওয়াদতানা আলা ৰুছুলিকা ওয়া লা তুখযিনা ইয়াওমাল ক্বিয়ামাহ ইন্নাকা লা তুখলিফুল মীআদ",
      "assamese": "হে আমাৰ ৰব! আপোনাৰ ৰাছুলসকলৰ জৰিয়তে আমাক যি প্ৰতিশ্ৰুতি দিছে সেয়া আমাক প্ৰদান কৰক আৰু কিয়ামতৰ দিনা আমাক অপমানিত নকৰিব। নিশ্চয় আপুনি প্ৰতিশ্ৰুতি ভংগ নকৰে।",
      "reference": "Surah Ali 'Imran (3:194)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا فَاكْتُبْنَا مَعَ الشَّاهِدِينَ",
      "transliteration": "ৰব্বানা আমান্না ফাক্তুবনা মাআশ শাহিদীন",
      "assamese": "হে আমাৰ ৰব! আমি ঈমান আনিছোঁ, গতিকে আমাক সাক্ষীসকলৰ অন্তৰ্ভুক্ত কৰক।",
      "reference": "Surah Al-Ma'idah (5:83)"
    },
    {
      "arabic": "رَبَّنَا أَنْزِلْ عَلَيْنَا مَائِدَةً مِنَ السَّمَاءِ تَكُونُ لَنَا عِيدًا لِأَوَّلِنَا وَآخِرِنَا وَآيَةً مِنْكَ ۖ وَارْزُقْنَا وَأَنْتَ خَيْرُ الرَّازِقِينَ",
      "transliteration": "ৰব্বানা আনযিল আলাইনা মাইদাতাম মিনাছ্ ছামাই তাকুনু লানা ইদাল্লি আউয়ালিনা ওয়া আখিৰিনা ওয়া আয়াতাম মিনকা ওয়াৰযুক্বনা ওয়া আন্তা খাইৰুৰ ৰাযিক্বীন",
      "assamese": "হে আমাৰ ৰব! আমাৰ বাবে আকাশৰ পৰা খাদ্য ভৰ্তি এখন টেবুল নাজিল কৰক, যিটো আমাৰ আদি আৰু অন্তৰ সকলোৰে বাবে হ'ব আনন্দৰ উৎস আৰু আপোনাৰ ফালৰ পৰা এটা নিদৰ্শন। আমাক ৰিযিক দান কৰক, কাৰণ আপুনি হ'ল শ্ৰেষ্ঠ ৰিযিকদাতা।",
      "reference": "Surah Al-Ma'idah (5:114)"
    },
    {
      "arabic": "رَبَّنَا ظَلَمْنَا أَنْفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ",
      "transliteration": "ৰব্বানা যালামনা আনফুছানা ওয়া ইল্লাম তাগফিৰ লানা ওয়া তাৰহামনা লানাকুনান্না মিনাল খাছিৰীন",
      "assamese": "হে আমাৰ ৰব! আমি নিজৰ ওপৰত অন্যায় কৰিছোঁ। যদি আপুনি আমাক ক্ষমা নকৰে আৰু আমাক দয়া নকৰে, তেন্তে আমি নিশ্চয় ক্ষতিগ্রস্তসকলৰ মাজত অন্তৰ্ভুক্ত হ'ম।",
      "reference": "Surah Al-A'raf (7:23)"
    },
    {
      "arabic": "رَبَّنَا لَا تَجْعَلْنَا مَعَ الْقَوْمِ الظَّالِمِينَ",
      "transliteration": "ৰব্বানা লা তাজআলনা মাআল ক্বাওমিয যালিমীন",
      "assamese": "হে আমাৰ ৰব! আমাক অন্যায়কাৰীসকলৰ সঙ্গী নকৰিব।",
      "reference": "Surah Al-A'raf (7:47)"
    },
    {
      "arabic": "رَبَّنَا افْتَحْ بَيْنَنَا وَبَيْنَ قَوْمِنَا بِالْحَقِّ وَأَنْتَ خَيْرُ الْفَاتِحِينَ",
      "transliteration": "ৰব্বানাফতাহ বাইনানা ওয়া বাইনা ক্বাওমিনা বিল হাক্কি ওয়া আন্তা খাইৰুল ফাতিহীন",
      "assamese": "হে আমাৰ ৰব! আমাৰ আৰু আমাৰ সম্প্ৰদায়ৰ মাজত সত্যৰ সৈতে ফয়ছলা কৰি দিয়ক, কাৰণ আপুনিয়েই হ'ল সৰ্বশ্ৰেষ্ঠ ফয়ছলাকাৰী।",
      "reference": "Surah Al-A'raf (7:89)"
    },
    {
      "arabic": "رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَتَوَفَّنَا مُسْلِمِينَ",
      "transliteration": "ৰব্বানা আফৰিগ আলাইনা ছাবৰাওঁ ওয়া তাওয়াফ্ফানা মুছ্লিমীন",
      "assamese": "হে আমাৰ ৰব! আমাক পূৰ্ণ ধৈৰ্য্য দান কৰক আৰু আমাক মুছলিম হিচাপে মৃত্যু দান কৰক।",
      "reference": "Surah Al-A'raf (7:126)"
    },
    {
      "arabic": "رَبَّنَا لَا تَجْعَلْنَا فِتْنَةً لِلْقَوْمِ الظَّالِمِينَ وَنَجِّنَا بِرَحْمَتِكَ مِنَ الْقَوْمِ الْكَافِرِينَ",
      "transliteration": "ৰব্বানা লা তাজআলনা ফিত্নাতাল লিল-ক্বাওমিয যালিমীন ওয়া নাজ্জিনা বিৰাহমাতিকা মিনাল ক্বাওমিল কাফিৰীন",
      "assamese": "হে আমাৰ ৰব! আমাক অন্যায়কাৰীসকলৰ পৰীক্ষাৰ পাত্ৰ নকৰিব; আৰু আপোনাৰ অনুগ্ৰহেৰে আমাক কাফিৰ সম্প্ৰদায়ৰ পৰা ৰক্ষা কৰক।",
      "reference": "Surah Yunus (10:85-86)"
    },
    {
      "arabic": "رَبَّنَا إِنَّكَ تَعْلَمُ مَا نُخْفِي وَمَا نُعْلِنُ ۗ وَمَا يَخْفَىٰ عَلَى اللَّهِ مِنْ شَيْءٍ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ",
      "transliteration": "ৰব্বানা ইন্নাকা তালামু মা নুখফি ওয়া মা নুলিনু ওয়া মা ইয়াখফা আলাল্লাহি মিন শাইয়িন ফিল আৰযি ওয়ালা ফিছ্ ছামাই",
      "assamese": "হে আমাৰ ৰব! আমি যি গোপন কৰোঁ আৰু যি প্ৰকাশ কৰোঁ সেয়া নিশ্চয় আপুনি জানে। পৃথিৱী আৰু আকাশৰ কোনো বস্তুৱেই আল্লাহৰ ওচৰত গোপন নহয়।",
      "reference": "Surah Ibrahim (14:38)"
    },
    {
      "arabic": "رَبَّنَا وَتَقَبَّلْ دُعَاءِ",
      "transliteration": "ৰব্বানা ওয়া তাক্বাব্বল দুআ",
      "assamese": "হে আমাৰ ৰব! মোৰ প্ৰাৰ্থনা কবুল কৰক।",
      "reference": "Surah Ibrahim (14:40)"
    },
    {
      "arabic": "رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْমَ يَقُومُ الْحِسَابُ",
      "transliteration": "ৰব্বানাগফিৰ লি ওয়ালি-ওয়ালিদাইয়্যা ওয়ালিল মুমিনিনা ইয়াওমা ইয়াক্বুমুল হিছাব",
      "assamese": "হে আমাৰ ৰব! হিচাপ লোৱাৰ দিনা মোক, মোৰ মাক-দেউতাকক আৰু সকলো মুমিনক ক্ষমা কৰি দিব।",
      "reference": "Surah Ibrahim (14:41)"
    },
    {
      "arabic": "رَبَّنَا آتِنَا مِنْ لَدُنْكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا",
      "transliteration": "ৰব্বানা আতিনা মিল্লাদুনকা ৰাহমাতাওঁ ওয়া হাইয়্যি লানা মিন আমৰিনা ৰাশাদা",
      "assamese": "হে আমাৰ ৰব! আমাক আপোনাৰ ফালৰ পৰা ৰহমত দান কৰক আৰু আমাৰ কাম-কাজবোৰ সঠিকভাৱে পৰিচালনা কৰাৰ ব্যৱস্থা কৰক।",
      "reference": "Surah Al-Kahf (18:10)"
    },
    {
      "arabic": "رَبَّنَا إِنَّنَا نَخَافُ أَنْ يَفْرُطَ عَلَيْنَا أَوْ أَنْ يَطْغَىٰ",
      "transliteration": "ৰব্বানা ইন্নানা নাখাফু আই ইয়াফৰুতা আলাইনা আও আই ইয়াতগা",
      "assamese": "হে আমাৰ ৰব! আমি ভয় কৰিছোঁ যে সি আমাৰ ওপৰত অন্যায় কৰিব পাৰে বা উদ্ধতালি কৰিব পাৰে।",
      "reference": "Surah Ta-Ha (20:45)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا فَاغْفِرْ لَنَا وَارْحَمْنَا وَأَنْتَ خَيْرُ الرَّاحِمِينَ",
      "transliteration": "ৰব্বানা আমান্না ফাগফিৰ লানা ওয়াৰহামনা ওয়া আন্তা খাইৰুৰ ৰাহিমীন",
      "assamese": "হে আমাৰ ৰব! আমি ঈমান আনিছোঁ, গতিকে আমাক ক্ষমা কৰক আৰু আমাৰ ওপৰত দয়া কৰক; কাৰণ আপুনিয়েই শ্ৰেষ্ঠ দয়ালু।",
      "reference": "Surah Al-Mu'minun (23:109)"
    },
    {
      "arabic": "رَبَّنَا اصْرِفْ عَنَّا عَذَابَ جَهَنَّمَ ۖ إِنَّ عَذَابَهَا كَانَ غَرَامًا",
      "transliteration": "ৰব্বানাছ্-ৰিফ আন্না আযাবা জাহান্নামা ইন্না আযাবাহা কানা গাৰামা",
      "assamese": "হে আমাৰ ৰব! আমাৰ পৰা জাহান্নামৰ শাস্তি আঁতৰাই ৰাখক। নিশ্চয় ইয়াৰ শাস্তি অতি ভয়াবহ।",
      "reference": "Surah Al-Furqan (25:65)"
    },
    {
      "arabic": "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا",
      "transliteration": "ৰব্বানা হাব লানা মিন আযওয়াজিনা ওয়া যুৰৰিয়্যাতিনা ক্বুৰৰাতা আইয়ুনি ওয়াজআলনা লিল মুত্তাক্বিনা ইমামা",
      "assamese": "হে আমাৰ ৰব! আমাক এনেকুৱা পত্নী আৰু সন্তান দান কৰক যিসকল আমাৰ চকুৰ শীতল হ'ব, আৰু আমাক মুত্তাক্বীসকলৰ ইমাম বনাই দিয়ক।",
      "reference": "Surah Al-Furqan (25:74)"
    },
    {
      "arabic": "رَبَّنَا لَغَفُورٌ شَكُورٌ",
      "transliteration": "ৰব্বানা লাগাফুৰুন শাকুৰ",
      "assamese": "আমাৰ ৰব নিশ্চয় ক্ষমাশীল আৰু গুণগ্ৰাহী।",
      "reference": "Surah Fatir (35:34)"
    },
    {
      "arabic": "رَبَّنَا وَسِعْتَ كُلَّ شَيْءٍ رَحْمَةً وَعِلْمًا فَاغْفِرْ لِلَّذِينَ تَابُوا وَاتَّبَعُوا سَبِيلَكَ وَقِهِمْ عَذَابَ الْجَحِيمِ",
      "transliteration": "ৰব্বানা ওয়াছিআতা কুল্লা শাইয়ি ৰাহমাতাওঁ ওয়া ইলমান ফাগফিৰ লিল্লাযিনা তাবু ওয়াত্তাবাউ ছাবিলকা ওয়াক্বিহিম আযাবাল জাহীম",
      "assamese": "হে আমাৰ ৰব! আপোনাৰ ৰহমত আৰু জ্ঞান সকলো বস্তুকে আবৰি আছে। গতিকে যিসকলে তওবা কৰিছে আৰু আপোনাৰ পথ অনুসৰণ কৰিছে তেওঁলোকক ক্ষমা কৰক আৰু জাহান্নামৰ জুইৰ পৰা বচাওক।",
      "reference": "Surah Ghafir (40:7)"
    },
    {
      "arabic": "رَبَّنَا وَأَدْخِلْهُمْ جَنَّاتِ عَدْنٍ الَّتِي وَعَدْتَهُمْ وَمَنْ صَلَحَ مِنْ آبَائِهِمْ وَأَزْوَاجِهِمْ وَذُرِّيَّاتِهِمْ ۚ إِنَّكَ أَنْتَ الْعَزِيزُ الْحَكِيمُ",
      "transliteration": "ৰব্বানা ওয়া আদখিলহুম জান্নাতি আদনিনিল্লাতি ওয়াদতাহুম ওয়া মান ছালাহা মিন আবাইহিম ওয়া আযওয়াজিহিম ওয়া যুৰৰিয়্যাতিহিম ইন্নাকা আন্তাল আযিযুল হাকীম",
      "assamese": "হে আমাৰ ৰব! তেওঁলোকক স্থায়ী জান্নাতত প্ৰৱেশ কৰাওক যাৰ প্ৰতিশ্ৰুতি আপুনি তেওঁলোকক দিছে; আৰু তেওঁলোকৰ পিতৃ-মাতৃ, পত্নী আৰু সন্তানসকলৰ মাজৰ পৰা যিসকল নেক হ'ব তেওঁলোককো। নিশ্চয় আপুনি পৰাক্ৰমশালী, প্ৰজ্ঞাময়।",
      "reference": "Surah Ghafir (40:8)"
    },
    {
      "arabic": "رَبَّنَا اغْفِرْ لَنَا وَلِإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالْإِيمَانِ وَلَا تَجْعَلْ فِي قُلُوبِنَا غِلًّا لِلَّذِينَ آمَنُوا رَبَّنَا إِنَّكَ رَءُوفٌ رَحِيمٌ",
      "transliteration": "ৰব্বানাগফিৰ লানা ওয়া লি-ইখওয়ানিনাল্লাযিনা ছাবাক্বুনা বিল-ঈমানি ওয়া লা তাজআল ফি কুলুবিনা গিল্লাল লিল্লাযিনা আমানু ৰব্বানা ইন্নাকা ৰাউফুৰ ৰাহীম",
      "assamese": "হে আমাৰ ৰব! আমাক আৰু আমাৰ আগতে ঈমান অনা আমাৰ ভাইসকলক ক্ষমা কৰক, আৰু মুমিনসকলৰ বিৰুদ্ধে আমাৰ অন্তৰত কোনো ঘৃণা নাৰাখিব। হে আমাৰ ৰব! নিশ্চয় আপুনি অতি মৰমিয়াল, পৰম দয়ালু।",
      "reference": "Surah Al-Hashr (59:10)"
    },
    {
      "arabic": "رَبَّنَا عَلَيْكَ تَوَكَّلْنَا وَإِلَيْكَ أَنَبْنَا وَإِلَيْكَ الْمَصِيرُ",
      "transliteration": "ৰব্বানা আলাইকা তাওয়াক্কালনা ওয়া ইলাইকা আনাবনা ওয়া ইলাইকাল মাছীৰ",
      "assamese": "হে আমাৰ ৰব! আমি কেৱল আপোনাৰ ওপৰতেই ভৰসা কৰিছোঁ, আপোনাৰ ফালেই প্ৰত্যাৱৰ্তন কৰিছোঁ আৰু আপোনাৰ ওচৰতেই আমাৰ শেষ লক্ষ্য।",
      "reference": "Surah Al-Mumtahanah (60:4)"
    },
    {
      "arabic": "رَبَّنَا لَا تَجْعَلْنَا فِتْنَةً لِلَّذِينَ كَفَرُوا وَاغْفِرْ لَنَا رَبَّنَا ۖ إِنَّكَ أَنْتَ الْعَزِيزُ الْحَكِيمُ",
      "transliteration": "ৰব্বানা লা তাজআলনা ফিত্নাতাল লিল্লাযিনা কাফাৰু ওয়াগফিৰ লানা ৰব্বানা ইন্নাকা আন্তাল আযিযুল হাকীম",
      "assamese": "হে আমাৰ ৰব! আমাক কাফিৰসকলৰ পৰীক্ষাৰ পাত্ৰ নকৰিব আৰু আমাক ক্ষমা কৰক। হে আমাৰ ৰব! নিশ্চয় আপুনি মহা পৰাক্ৰমশালী, প্ৰজ্ঞাময়।",
      "reference": "Surah Al-Mumtahanah (60:5)"
    },
    {
      "arabic": "رَبَّنَا أَتْمِمْ لَنَا نُورَنَا وَاغْفِرْ لَنَا ۖ إِنَّكَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ",
      "transliteration": "ৰব্বানা আতমিম লানা নুৰানা ওয়াগফিৰ লানা ইন্নাকা আলা কুল্লি শাইয়িন ক্বাদ্বীৰ",
      "assamese": "হে আমাৰ ৰব! আমাৰ বাবে আমাৰ নূর (জ্যোতি) পূৰ্ণ কৰি দিয়ক আৰু আমাক ক্ষমা কৰক। নিশ্চয় আপুনি সকলো বস্তুৰ ওপৰত ক্ষমতাশালী।",
      "reference": "Surah At-Tahrim (66:8)"
    },
    {
      "arabic": "رَبَّنَا آمَنَّا فَاغْفِرْ لَنَا ذُنُوبَنَا وَقِنَا عَذَابَ النَّارِ",
      "transliteration": "ৰব্বানা আমান্না ফাগফিৰ লানা যুনুবানা ৱাক্বিনা আযাবান নাৰ",
      "assamese": "হে আমাৰ ৰব! আমি ঈমান আনিছোঁ, গতিকে আমাৰ পাপবোৰ ক্ষমা কৰক আৰু আমাক জাহান্নামৰ জুইৰ শাস্তিৰ পৰা ৰক্ষা কৰক।",
      "reference": "Surah Ali 'Imran (3:16)"
    },
  ];

  // --- METHODS ---

  void _copyDua(int index, List<Map<String, String>> currentDuas) {
    final dua = currentDuas[index];
    // Find the available translation for the clipboard
    String translationText = dua['translation'] ??
        dua['hindi'] ??
        dua['bengali'] ??
        dua['assamese'] ??
        "";

    final text = "${widget.title} ${index +
        1}\n${dua['arabic']}\n\n$translationText\n${dua['reference']}";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  void _shareDua(int index, List<Map<String, String>> currentDuas) {
    final dua = currentDuas[index];
    // Find the available translation for sharing
    String translationText = dua['translation'] ??
        dua['hindi'] ??
        dua['bengali'] ??
        dua['assamese'] ??
        "";

    final text = "${widget.title} ${index +
        1}\n${dua['arabic']}\n\n$translationText\n${dua['reference']}";
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = Provider
        .of<SettingsService>(context)
        .fontScale;
    final theme = Theme.of(context);
    final currentDuas = _getLocalizedList();

    return Scaffold(
      backgroundColor: const Color(0xFF006A4E),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E9),
        title: Text(widget.title,
            style: TextStyle(fontSize: 18 * fontScale,
                color: const Color(0xFF1B5E20),
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: currentDuas.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final dua = currentDuas[index];
          final bool isHighlighted = _highlightedIndex == index;

          // FIND TRANSLATION SAFELY
          String translationText = dua['translation'] ??
              dua['hindi'] ??
              dua['bengali'] ??
              dua['assamese'] ??
              "Translation not available";

          return GestureDetector(
            onLongPress: () {
              HapticFeedback.lightImpact();
              setState(() =>
              _highlightedIndex = (isHighlighted ? null : index));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isHighlighted ? _highlightColor : theme.cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isHighlighted ? _highlightBorderColor : theme
                      .dividerColor.withOpacity(0.08),
                  width: isHighlighted ? 2.0 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Rabbana ${index + 1}",
                        style: TextStyle(
                          color: isHighlighted ? _highlightBorderColor : theme
                              .colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.copy_rounded, size: 20,
                                color: isHighlighted
                                    ? _highlightBorderColor
                                    : Colors.grey),
                            onPressed: () => _copyDua(index, currentDuas),
                          ),
                          IconButton(
                            icon: Icon(Icons.share_rounded, size: 20,
                                color: isHighlighted
                                    ? _highlightBorderColor
                                    : Colors.grey),
                            onPressed: () => _shareDua(index, currentDuas),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(dua['arabic']!,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 24 * fontScale,
                        fontFamily: 'Amiri',
                        height: 1.8),
                  ),
                  const SizedBox(height: 16),
                  Text(dua['transliteration']!,
                    style: TextStyle(fontSize: 14 * fontScale,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  // FIX: Used translationText variable instead of dua['translation']!
                  Text(translationText,
                    style: TextStyle(fontSize: 15 * fontScale, height: 1.4),
                  ),
                  const Divider(height: 32),
                  Text(dua['reference']!,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontSize: 12 * fontScale, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}