import '../models/company.dart';

class CompanyData {
  static final List<Company> companies = _rawData.map((data) => Company.fromMap(data)).toList();

  static const List<Map<String, String>> _rawData = [
    {
      "company_name": "DEJOUR MATRIX PRIVATE LIMITED",
      "cin": "U45309TN2022PTC156694",
      "registration_number": "156694",
      "date_of_incorporation": "17 November 2022",
      "address": "No.1/361, Valar Nagar, Siva Siva Block, Ambalaranpatti, Madurai, Madurai, Tamil Nadu, India - 625107"
    },
    {
      "company_name": "JOURWIN MATRIX PRIVATE LIMITED",
      "cin": "U15114TN2022PTC157065",
      "registration_number": "157065",
      "date_of_incorporation": "2 December 2022",
      "address": "No.13/202-21, Saral Nagar, Kallurani, Tirunelveli, Tirunelveli, Tamil Nadu, India - 627808"
    },
    {
      "company_name": "JOUR & JOUR INDIA PRIVATE LIMITED",
      "cin": "U52100TN2022PTC157477",
      "registration_number": "157477",
      "date_of_incorporation": "17 December 2022",
      "address": "No.1/361, Valar Nagar, Siva Siva Block, Ambalakaranpatti, Madurai, Madurai, Tamil Nadu, India - 625107"
    },
    {
      "company_name": "DEJO PACKERS & MOVERS PRIVATE LIMITED",
      "cin": "U63000TN2022PTC157532",
      "registration_number": "157532",
      "date_of_incorporation": "20 December 2022",
      "address": "Plot No.6, Agasthiyar Street, Podi Line Nehru Nagar, Madurai, Madurai, Tamil Nadu, India - 625016"
    },
    {
      "company_name": "JOURMA RECRUITERS INDIA PRIVATE LIMITED",
      "cin": "U74910TN2022PTC157760",
      "registration_number": "157760",
      "date_of_incorporation": "28 December 2022",
      "address": "No.1/361A, Valar Nagar, Siva Siva Block, Ambalakaranpatti, Madurai, Madurai, Tamil Nadu, India - 625107"
    },
    {
      "company_name": "YABESH INFOTECH PRIVATE LIMITED",
      "cin": "U72900TZ2022PTC040655",
      "registration_number": "040655",
      "date_of_incorporation": "30 December 2022",
      "address": "No.203C, Ottupattarai, Coonoor, Nilgiris, Tamil Nadu, India - 643105"
    },
    {
      "company_name": "REJO KITCHEN PRIVATE LIMITED",
      "cin": "U55209TN2023PTC158119",
      "registration_number": "158119",
      "date_of_incorporation": "9 January 2023",
      "address": "No.1/361A, Valar Nagar, Siva Siva Block, Ambalakaranpatti, Madurai, Madurai, Tamil Nadu, India - 625107"
    },
    {
      "company_name": "DEVEST INDIA GARMENTS PRIVATE LIMITED",
      "cin": "U18109TN2023PTC158385",
      "registration_number": "158385",
      "date_of_incorporation": "20 January 2023",
      "address": "No.1/361, Valar Nagar, Siva Siva Block, Ambalakaranpatti, Madurai, Madurai, Tamil Nadu, India - 625107"
    },
    {
      "company_name": "JOURNATURE AGRI INDIA PRIVATE LIMITED",
      "cin": "U46301TN2023PTC161648",
      "registration_number": "161648",
      "date_of_incorporation": "4 July 2023",
      "address": "No.13/202-30, Saral Nagar, Kallurani, Pavoorchatram, Tirunelveli, Alangulam, Tamil Nadu, India - 627808"
    },
    {
      "company_name": "TRIXNATURE RETAILERS PRIVATE LIMITED",
      "cin": "U47211TN2023PTC162134",
      "registration_number": "162134",
      "date_of_incorporation": "21 July 2023",
      "address": "No.13/202-30, Saral Nagar, Kallurani, Pavoorchatram, Tirunelveli, Alangulam, Tamil Nadu, India - 627808"
    },
    {
      "company_name": "JOURAGE ADVERTISING PRIVATE LIMITED",
      "cin": "U82300TN2023PTC162503",
      "registration_number": "162503",
      "date_of_incorporation": "2 August 2023",
      "address": "No.13/202-30, Saral Nagar, Kallurani, Pavoorchatram, Tirunelveli, Alangulam, Tamil Nadu, India - 627808"
    },
    {
      "company_name": "JOURNAX PRODUCTIONS PRIVATE LIMITED",
      "cin": "U59113TN2023PTC162881",
      "registration_number": "162881",
      "date_of_incorporation": "18 August 2023",
      "address": "No.13/202-30, Saral Nagar, Kallurani, Pavoorchatram, Tirunelveli, Alangulam, Tamil Nadu, India - 627808"
    },
    {
      "company_name": "JOUR STONE GRANITES PRIVATE LIMITED",
      "cin": "U08103TN2024PTC168597",
      "registration_number": "168597",
      "date_of_incorporation": "18 March 2024",
      "address": "No.13/202-21, Saral Nagar, Kallurani, Pavoorchatram, Tirunelveli, Tenkasi, Tamil Nadu, India - 627808"
    },
    {
      "company_name": "JOURMAL FOODY PRIVATE LIMITED",
      "cin": "U46309TN2024PTC168801",
      "registration_number": "168801",
      "date_of_incorporation": "26 March 2024",
      "address": "No.13/202-30, Saral Nagar, Kallurani, Pavoorchatram, Tirunelveli, Tenkasi, Tamil Nadu, India - 627808"
    },
    {
      "company_name": "DEJOURIX EXPORTS PRIVATE LIMITED",
      "cin": "U10301TN2025PTC178304",
      "registration_number": "178304",
      "date_of_incorporation": "19 March 2025",
      "address": "No.13/202-30, Saral Nagar, Kallurani, Pavoorchatram, Tirunelveli, Tenkasi, Tamil Nadu, India - 627808"
    },
    {
      "company_name": "ALAGU SWEETS & SNACKS PRIVATE LIMITED",
      "cin": "U10719TN2025PTC178358",
      "registration_number": "178358",
      "date_of_incorporation": "20 March 2025",
      "address": "No.5/2W, First VIP Golden City, Bodinayakanur, Theni, Bodinayakanur, Tamil Nadu, India - 625513"
    },
    {
      "company_name": "JOUR CONFECTIONERY PRIVATE LIMITED",
      "cin": "U10711TN2025PTC179345",
      "registration_number": "179345",
      "date_of_incorporation": "16 April 2025",
      "address": "No.13/202-30, Saral Nagar, Kallurani, Pavoorchatram, Tirunelveli, Tenkasi, Tamil Nadu, India - 627808"
    }
  ];
}
