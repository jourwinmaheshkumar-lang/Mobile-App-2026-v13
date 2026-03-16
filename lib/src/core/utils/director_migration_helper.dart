import '../repositories/director_repository.dart';
import '../models/director.dart';

class DirectorMigrationHelper {
  static final List<Map<String, String>> _migrationData = [
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "17Th November, 2022",
      "Company": "Dejour Matrix Private Limited"
    },
    {
      "Din": "09794582",
      "Name": "Mahadevan L",
      "Designation": "Director",
      "Appointment": "17Th November, 2022",
      "Company": "Dejour Matrix Private Limited"
    },
    {
      "Din": "09794583",
      "Name": "Sankar P",
      "Designation": "Director",
      "Appointment": "17Th November, 2022",
      "Company": "Dejour Matrix Private Limited"
    },
    {
      "Din": "10561638",
      "Name": "Banupriya S",
      "Designation": "Director",
      "Appointment": "25Th March, 2024",
      "Company": "Dejour Matrix Private Limited"
    },
    {
      "Din": "10561676",
      "Name": "Dineshbabu M",
      "Designation": "Director",
      "Appointment": "25Th March, 2024",
      "Company": "Dejour Matrix Private Limited"
    },
    {
      "Din": "10561629",
      "Name": "Nagarajan C S",
      "Designation": "Director",
      "Appointment": "25Th March, 2024",
      "Company": "Dejour Matrix Private Limited"
    },
    {
      "Din": "10561642",
      "Name": "Raja Bharathi L N",
      "Designation": "Director",
      "Appointment": "25Th March, 2024",
      "Company": "Dejour Matrix Private Limited"
    },
    {
      "Din": "10561610",
      "Name": "Ramar B",
      "Designation": "Director",
      "Appointment": "25Th March, 2024",
      "Company": "Dejour Matrix Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "2Nd December, 2022",
      "Company": "Jourwin Matrix Private Limited"
    },
    {
      "Din": "09810880",
      "Name": "Natarajan K L",
      "Designation": "Director",
      "Appointment": "2Nd December, 2022",
      "Company": "Jourwin Matrix Private Limited"
    },
    {
      "Din": "09810882",
      "Name": "Saravanan S",
      "Designation": "Director",
      "Appointment": "2Nd December, 2022",
      "Company": "Jourwin Matrix Private Limited"
    },
    {
      "Din": "10566501",
      "Name": "Kalpana Devi N",
      "Designation": "Director",
      "Appointment": "28Th March, 2024",
      "Company": "Jourwin Matrix Private Limited"
    },
    {
      "Din": "10565811",
      "Name": "Kalpana Karthick N B",
      "Designation": "Director",
      "Appointment": "28Th March, 2024",
      "Company": "Jourwin Matrix Private Limited"
    },
    {
      "Din": "10565747",
      "Name": "Kalyani R",
      "Designation": "Director",
      "Appointment": "28Th March, 2024",
      "Company": "Jourwin Matrix Private Limited"
    },
    {
      "Din": "10565789",
      "Name": "Senthilkumar K",
      "Designation": "Director",
      "Appointment": "28Th March, 2024",
      "Company": "Jourwin Matrix Private Limited"
    },
    {
      "Din": "10565980",
      "Name": "Vijaya Baskar L",
      "Designation": "Director",
      "Appointment": "28Th March, 2024",
      "Company": "Jourwin Matrix Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "17Th December, 2022",
      "Company": "Jour & Jour India Private Limited"
    },
    {
      "Din": "09827731",
      "Name": "Suresh R",
      "Designation": "Director",
      "Appointment": "17Th December, 2022",
      "Company": "Jour & Jour India Private Limited"
    },
    {
      "Din": "09827732",
      "Name": "Radha Krishnan M R",
      "Designation": "Director",
      "Appointment": "17Th December, 2022",
      "Company": "Jour & Jour India Private Limited"
    },
    {
      "Din": "09827903",
      "Name": "Ramasurendran M",
      "Designation": "Director",
      "Appointment": "17Th December, 2022",
      "Company": "Jour & Jour India Private Limited"
    },
    {
      "Din": "06732396",
      "Name": "Elangovan N",
      "Designation": "Director",
      "Appointment": "9Th May, 2024",
      "Company": "Jour & Jour India Private Limited"
    },
    {
      "Din": "10573913",
      "Name": "Karthikeyan N",
      "Designation": "Director",
      "Appointment": "9Th May, 2024",
      "Company": "Jour & Jour India Private Limited"
    },
    {
      "Din": "10574192",
      "Name": "Chitra Devi M",
      "Designation": "Director",
      "Appointment": "9Th May, 2024",
      "Company": "Jour & Jour India Private Limited"
    },
    {
      "Din": "10574215",
      "Name": "Devaki P",
      "Designation": "Director",
      "Appointment": "9Th May, 2024",
      "Company": "Jour & Jour India Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "20Th December, 2022",
      "Company": "Dejo Packers & Movers Private Limited"
    },
    {
      "Din": "09830303",
      "Name": "Paulpandi V",
      "Designation": "Director",
      "Appointment": "20Th December, 2022",
      "Company": "Dejo Packers & Movers Private Limited"
    },
    {
      "Din": "09830304",
      "Name": "Maheshkumar S",
      "Designation": "Director",
      "Appointment": "20Th December, 2022",
      "Company": "Dejo Packers & Movers Private Limited"
    },
    {
      "Din": "09830305",
      "Name": "Ashokkumar N",
      "Designation": "Director",
      "Appointment": "20Th December, 2022",
      "Company": "Dejo Packers & Movers Private Limited"
    },
    {
      "Din": "10577350",
      "Name": "Amutha S",
      "Designation": "Director",
      "Appointment": "4Th April, 2024",
      "Company": "Dejo Packers & Movers Private Limited"
    },
    {
      "Din": "10577903",
      "Name": "Kiruthika V",
      "Designation": "Director",
      "Appointment": "4Th April, 2024",
      "Company": "Dejo Packers & Movers Private Limited"
    },
    {
      "Din": "10577367",
      "Name": "Mahesh C",
      "Designation": "Director",
      "Appointment": "4Th April, 2024",
      "Company": "Dejo Packers & Movers Private Limited"
    },
    {
      "Din": "10577519",
      "Name": "Poobathi",
      "Designation": "Director",
      "Appointment": "4Th April, 2024",
      "Company": "Dejo Packers & Movers Private Limited"
    },
    {
      "Din": "10577510",
      "Name": "Subetha G",
      "Designation": "Director",
      "Appointment": "4Th April, 2024",
      "Company": "Dejo Packers & Movers Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "28Th December, 2022",
      "Company": "Jourma Recruiters India Private Limited"
    },
    {
      "Din": "09794583",
      "Name": "Sankar P",
      "Designation": "Director",
      "Appointment": "28Th December, 2022",
      "Company": "Jourma Recruiters India Private Limited"
    },
    {
      "Din": "09839528",
      "Name": "Asokan M",
      "Designation": "Director",
      "Appointment": "28Th December, 2022",
      "Company": "Jourma Recruiters India Private Limited"
    },
    {
      "Din": "09839529",
      "Name": "Namasivayam",
      "Designation": "Director",
      "Appointment": "28Th December, 2022",
      "Company": "Jourma Recruiters India Private Limited"
    },
    {
      "Din": "09839530",
      "Name": "Raja K",
      "Designation": "Director",
      "Appointment": "28Th December, 2022",
      "Company": "Jourma Recruiters India Private Limited"
    },
    {
      "Din": "10581183",
      "Name": "Jeyakeerthana T",
      "Designation": "Director",
      "Appointment": "18Th May, 2024",
      "Company": "Jourma Recruiters India Private Limited"
    },
    {
      "Din": "10581187",
      "Name": "Kowshika Lakshmi N",
      "Designation": "Director",
      "Appointment": "18Th May, 2024",
      "Company": "Jourma Recruiters India Private Limited"
    },
    {
      "Din": "10581191",
      "Name": "Saranya R",
      "Designation": "Director",
      "Appointment": "18Th May, 2024",
      "Company": "Jourma Recruiters India Private Limited"
    },
    {
      "Din": "10581196",
      "Name": "Sri Harini S",
      "Designation": "Director",
      "Appointment": "18Th May, 2024",
      "Company": "Jourma Recruiters India Private Limited"
    },
    {
      "Din": "10628573",
      "Name": "Thenmozhi R",
      "Designation": "Director",
      "Appointment": "18Th May, 2024",
      "Company": "Jourma Recruiters India Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "9Th January, 2023",
      "Company": "Rejo Kitchen Private Limited"
    },
    {
      "Din": "09855102",
      "Name": "Ajithkumar S",
      "Designation": "Director",
      "Appointment": "9Th January, 2023",
      "Company": "Rejo Kitchen Private Limited"
    },
    {
      "Din": "09855203",
      "Name": "Nagarani A",
      "Designation": "Director",
      "Appointment": "9Th January, 2023",
      "Company": "Rejo Kitchen Private Limited"
    },
    {
      "Din": "09855204",
      "Name": "Malar Jothi D",
      "Designation": "Director",
      "Appointment": "9Th January, 2023",
      "Company": "Rejo Kitchen Private Limited"
    },
    {
      "Din": "08118145",
      "Name": "Balamurugan A",
      "Designation": "Director",
      "Appointment": "23Rd May, 2024",
      "Company": "Rejo Kitchen Private Limited"
    },
    {
      "Din": "10631302",
      "Name": "Balasubramanian P",
      "Designation": "Director",
      "Appointment": "23Rd May, 2024",
      "Company": "Rejo Kitchen Private Limited"
    },
    {
      "Din": "09846160",
      "Name": "Lakshmikanth K R",
      "Designation": "Director",
      "Appointment": "23Rd May, 2024",
      "Company": "Rejo Kitchen Private Limited"
    },
    {
      "Din": "08739456",
      "Name": "Pratheesha S",
      "Designation": "Director",
      "Appointment": "23Rd May, 2024",
      "Company": "Rejo Kitchen Private Limited"
    },
    {
      "Din": "06428706",
      "Name": "Vinothkumar N",
      "Designation": "Director",
      "Appointment": "23Rd May, 2024",
      "Company": "Rejo Kitchen Private Limited"
    },
    {
      "Din": "10631341",
      "Name": "Yogesvari P",
      "Designation": "Director",
      "Appointment": "23Rd May, 2024",
      "Company": "Rejo Kitchen Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "20Th January, 2023",
      "Company": "Devest India Garments Private Limited"
    },
    {
      "Din": "09830305",
      "Name": "Ashokkumar N",
      "Designation": "Director",
      "Appointment": "20Th January, 2023",
      "Company": "Devest India Garments Private Limited"
    },
    {
      "Din": "09864368",
      "Name": "Anandan A M",
      "Designation": "Director",
      "Appointment": "20Th January, 2023",
      "Company": "Devest India Garments Private Limited"
    },
    {
      "Din": "09864369",
      "Name": "Naveenkumar K K",
      "Designation": "Director",
      "Appointment": "20Th January, 2023",
      "Company": "Devest India Garments Private Limited"
    },
    {
      "Din": "09864370",
      "Name": "Sowmmiya Narayanan S",
      "Designation": "Director",
      "Appointment": "20Th January, 2023",
      "Company": "Devest India Garments Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "30Th December, 2022",
      "Company": "Yabesh Infotech Private Limited"
    },
    {
      "Din": "09843276",
      "Name": "Mohamadali S",
      "Designation": "Director",
      "Appointment": "30Th December, 2022",
      "Company": "Yabesh Infotech Private Limited"
    },
    {
      "Din": "09843277",
      "Name": "Subendran A",
      "Designation": "Director",
      "Appointment": "30Th December, 2022",
      "Company": "Yabesh Infotech Private Limited"
    },
    {
      "Din": "09843278",
      "Name": "Shunmughasundaram T",
      "Designation": "Director",
      "Appointment": "30Th December, 2022",
      "Company": "Yabesh Infotech Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "4Th July, 2023",
      "Company": "Journature Agri India Private Limited"
    },
    {
      "Din": "10225471",
      "Name": "Gnanasekaran A",
      "Designation": "Director",
      "Appointment": "4Th July, 2023",
      "Company": "Journature Agri India Private Limited"
    },
    {
      "Din": "10225472",
      "Name": "Gunasekari P",
      "Designation": "Director",
      "Appointment": "4Th July, 2023",
      "Company": "Journature Agri India Private Limited"
    },
    {
      "Din": "10225473",
      "Name": "Sathyamoorthy B",
      "Designation": "Director",
      "Appointment": "4Th July, 2023",
      "Company": "Journature Agri India Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "21St July, 2023",
      "Company": "Trixnature Retailers Private Limited"
    },
    {
      "Din": "09846102",
      "Name": "Suruliraj R",
      "Designation": "Director",
      "Appointment": "21St July, 2023",
      "Company": "Trixnature Retailers Private Limited"
    },
    {
      "Din": "10249130",
      "Name": "Hariharan T N",
      "Designation": "Director",
      "Appointment": "21St July, 2023",
      "Company": "Trixnature Retailers Private Limited"
    },
    {
      "Din": "10249131",
      "Name": "Sangeetha S",
      "Designation": "Director",
      "Appointment": "21St July, 2023",
      "Company": "Trixnature Retailers Private Limited"
    },
    {
      "Din": "10249132",
      "Name": "Venkatesh K G",
      "Designation": "Director",
      "Appointment": "21St July, 2023",
      "Company": "Trixnature Retailers Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "2Nd August, 2023",
      "Company": "Jourage Advertising Private Limited"
    },
    {
      "Din": "09844744",
      "Name": "Prakash Kannan C S",
      "Designation": "Director",
      "Appointment": "2Nd August, 2023",
      "Company": "Jourage Advertising Private Limited"
    },
    {
      "Din": "10264257",
      "Name": "Buvaneswari C N",
      "Designation": "Director",
      "Appointment": "2Nd August, 2023",
      "Company": "Jourage Advertising Private Limited"
    },
    {
      "Din": "10264258",
      "Name": "Sathiya Narayanan S",
      "Designation": "Director",
      "Appointment": "2Nd August, 2023",
      "Company": "Jourage Advertising Private Limited"
    },
    {
      "Din": "10264259",
      "Name": "Pragadeesh Pandian S",
      "Designation": "Director",
      "Appointment": "2Nd August, 2023",
      "Company": "Jourage Advertising Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "18Th August, 2023",
      "Company": "Journax Productions Private Limited"
    },
    {
      "Din": "09844713",
      "Name": "Arunkumar S",
      "Designation": "Director",
      "Appointment": "18Th August, 2023",
      "Company": "Journax Productions Private Limited"
    },
    {
      "Din": "10282503",
      "Name": "Maheswari A",
      "Designation": "Director",
      "Appointment": "18Th August, 2023",
      "Company": "Journax Productions Private Limited"
    },
    {
      "Din": "10282504",
      "Name": "Sharmila N B",
      "Designation": "Director",
      "Appointment": "18Th August, 2023",
      "Company": "Journax Productions Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "18Th March, 2024",
      "Company": "Jour Stone Granites Private Limited"
    },
    {
      "Din": "10554209",
      "Name": "Naganathan S",
      "Designation": "Director",
      "Appointment": "18Th March, 2024",
      "Company": "Jour Stone Granites Private Limited"
    },
    {
      "Din": "10554210",
      "Name": "Thamaraikannan S",
      "Designation": "Director",
      "Appointment": "18Th March, 2024",
      "Company": "Jour Stone Granites Private Limited"
    },
    {
      "Din": "10554211",
      "Name": "Kalyani B",
      "Designation": "Director",
      "Appointment": "18Th March, 2024",
      "Company": "Jour Stone Granites Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "26Th March, 2024",
      "Company": "Jourmal Foody Private Limited"
    },
    {
      "Din": "09846185",
      "Name": "Prathipa R",
      "Designation": "Director",
      "Appointment": "26Th March, 2024",
      "Company": "Jourmal Foody Private Limited"
    },
    {
      "Din": "10564393",
      "Name": "Jayanth R",
      "Designation": "Director",
      "Appointment": "26Th March, 2024",
      "Company": "Jourmal Foody Private Limited"
    },
    {
      "Din": "10564394",
      "Name": "Perumal Raj R",
      "Designation": "Director",
      "Appointment": "26Th March, 2024",
      "Company": "Jourmal Foody Private Limited"
    },
    {
      "Din": "10564395",
      "Name": "Vimal M",
      "Designation": "Director",
      "Appointment": "26Th March, 2024",
      "Company": "Jourmal Foody Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "19Th March, 2025",
      "Company": "Dejourix Exports Private Limited"
    },
    {
      "Din": "11008423",
      "Name": "Ajay Samuel S",
      "Designation": "Director",
      "Appointment": "19Th March, 2025",
      "Company": "Dejourix Exports Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "20Th March, 2025",
      "Company": "Alagu Sweets & Snacks Private Limited"
    },
    {
      "Din": "09855102",
      "Name": "Ajithkumar S",
      "Designation": "Director",
      "Appointment": "20Th March, 2025",
      "Company": "Alagu Sweets & Snacks Private Limited"
    },
    {
      "Din": "09843277",
      "Name": "Subendran A",
      "Designation": "Director",
      "Appointment": "20Th March, 2025",
      "Company": "Alagu Sweets & Snacks Private Limited"
    },
    {
      "Din": "09794581",
      "Name": "Jaya Anand S",
      "Designation": "Director",
      "Appointment": "16Th April, 2025",
      "Company": "Jour Confectionery Private Limited"
    },
    {
      "Din": "11008423",
      "Name": "Ajay Samuel S",
      "Designation": "Director",
      "Appointment": "16Th April, 2025",
      "Company": "Jour Confectionery Private Limited"
    },
    {
      "Din": "07404691",
      "Name": "Manoharan P",
      "Designation": "Director",
      "Appointment": "",
      "Company": ""
    },
    {
      "Din": "10574294",
      "Name": "Ravi S",
      "Designation": "Director",
      "Appointment": "",
      "Company": ""
    }
  ];

  static Future<int> migrateDirectorCompanies() async {
    final repo = DirectorRepository();
    await repo.loadAll();
    final allDirectors = repo.all;
    
    int updateCount = 0;
    
    // Group migration data by DIN
    Map<String, List<CompanyDetail>> groupedData = {};
    for (var data in _migrationData) {
      String rawDin = data['Din']?.trim() ?? '';
      if (rawDin.isEmpty) continue;
      
      // Pad 7-digit DINs to 8 digits
      String din = rawDin;
      final digitsOnly = rawDin.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length == 7) {
        din = '0$digitsOnly';
      }
      
      final company = data['Company']?.trim() ?? '';
      if (company.isEmpty) continue;

      final detail = CompanyDetail(
        companyName: company,
        designation: data['Designation'] ?? 'Director',
        appointmentDate: data['Appointment'] ?? '',
      );
      
      if (!groupedData.containsKey(din)) {
        groupedData[din] = [];
      }
      groupedData[din]!.add(detail);
    }
    
    // Update existing directors
    for (var entry in groupedData.entries) {
      final din = entry.key;
      final newCompanies = entry.value;
      
      // Find matching directors (DIN can match multiple if there are duplicates in DB, but usually unique)
      final existingMatches = allDirectors.where((d) => d.din.trim() == din).toList();
      
      if (existingMatches.isEmpty) {
        // DIN not found in existing app data, skip as per requirement
        continue;
      }
      
      for (var director in existingMatches) {
        // Merge companies, avoid exact duplicates
        List<CompanyDetail> mergedCompanies = List.from(director.companies);
        
        for (var newC in newCompanies) {
          bool exists = mergedCompanies.any((existingC) => 
            existingC.companyName.toLowerCase() == newC.companyName.toLowerCase() &&
            existingC.designation.toLowerCase() == newC.designation.toLowerCase()
          );
          
          if (!exists) {
            mergedCompanies.add(newC);
          }
        }
        
        // Update director record
        if (mergedCompanies.length > director.companies.length) {
          await repo.update(director.copyWith(companies: mergedCompanies));
          updateCount++;
        }
      }
    }
    
    return updateCount;
  }
}
