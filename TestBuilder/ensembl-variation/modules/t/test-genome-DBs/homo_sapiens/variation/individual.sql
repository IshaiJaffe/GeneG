-- MySQL dump 10.9
--
-- Host: ecs2    Database: _test_db_homo_sapiens_variation_dr2_25_11_12432
-- ------------------------------------------------------
-- Server version	4.1.12-log


--
-- Table structure for table `individual`
--

CREATE TABLE `individual` (
  `gender` enum('Male','Female','Unknown') NOT NULL default 'Unknown',
  `sample_id` int(11) NOT NULL default '0',
  `father_individual_sample_id` int(11) default NULL,
  `mother_individual_sample_id` int(11) default NULL,
  PRIMARY KEY  (`sample_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;



