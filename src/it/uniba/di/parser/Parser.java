package it.uniba.di.parser;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import it.uniba.di.application.Program;
import it.uniba.di.support.Utility;

public class Parser extends Utility {

	private static final String CONTROL_OVERHEAD = "m_controlOverhead";
	private static final String MALICIOUS_OVERHEAD = "m_maliciousOverhead";
	private static final String INTERCEPTED_BLACKHOLE = "m_interceptedBlackhole";
	private static final String RATE_OF_SUCCESS_PER_RUN = "m_rateOfSuccess_r";
	private static final String RATE_OF_SUCCESS_PER_RUN_TRIAL = "m_rateOfSuccess_s";
	private static final String ROUTING_TABLE_SIZE = "m_routingTableSize";
	private static final String ROUTING_TABLE_UPDATE = "m_updateRoutingTable";

	public static List<String> getList(String fileName) throws IOException {
		List<String> list = new ArrayList<>();

		try (FileReader in = new FileReader(fileName); BufferedReader br = new BufferedReader(in)) {
			String line;
			while ((line = br.readLine()) != null) {
				if (line.equals("<State " + 1 + " (controlled)>")) {
					line = br.readLine();
					while ((!line.equals("</State " + 1 + " (controlled)>") && line != null)) {
						if (!line.contains("{") || !line.contains("}")) {
							if (line.startsWith("m_")) {
								int equalIndex = line.indexOf("=");
								list.add(line.substring(0, equalIndex));
							}
						}
						line = br.readLine();
					}
					break;
				}
			}
		}

		return list;
	}

	/*
	 * default case: it will process all metrics
	 */
	public static void parser(Date executionDate, String fileName, String numRun, String numHost, String valMobility) throws IOException {
		File outputFile;
		
		try (FileReader in = new FileReader(fileName); BufferedReader br = new BufferedReader(in)) {
			outputFile = new File("result\\output_" + Program.dateFileFormat.format(executionDate) + "_RUN" + numRun
					+ "_HOST" + numHost + "_MOB" + valMobility + ".csv");
			outputFile.createNewFile();
			FileWriter fw = new FileWriter(outputFile);
			BufferedWriter bw = new BufferedWriter(fw);

			HashMap<String, Number> hmap = new HashMap<>();
			bw.write("sep=,\n");
			List metricList = new ArrayList<>(Program.selectedParameter);
			if (metricList.contains(RATE_OF_SUCCESS_PER_RUN)
					&& Program.selectedParameter.contains(RATE_OF_SUCCESS_PER_RUN_TRIAL)) {
				metricList.remove(RATE_OF_SUCCESS_PER_RUN);
				metricList.remove(RATE_OF_SUCCESS_PER_RUN_TRIAL);
				metricList.add("m_rateSUCCESS");
				metricList.add("m_rateTRIAL");
				metricList.add("m_rateOfSuccess");
			}
			if (metricList.contains(CONTROL_OVERHEAD)) {
				metricList.add("m_control_RREQs");
				metricList.add("m_control_RREPs");
				metricList.add("m_control_RERRs");
				if (modeNAODV() || modeBNAODV()) {
					metricList.add("m_control_NACKs");
				}
				if (modeBNAODV()) {
					metricList.add("m_control_CHLs");
					metricList.add("m_control_RESs");
				}
			}

			if (metricList.contains(INTERCEPTED_BLACKHOLE) && modeBNAODV()) {
				metricList.add("m_intercepted_true_positive");
				metricList.add("m_intercepted_false_positive");
			}

			Collections.sort(metricList);
			writeHeader(bw, metricList);

			String line;
			int stateCounter = 1;
			int localTrialCounter = 0, globalTrialCounter = 0;
			int localSuccessCounter = 0, globalSuccessCounter = 0;
			int localCoCounter = 0, globalCoCounter = 0;
			int localMoCounter = 0, globalMoCounter = 0;
			int localBhCounter = 0, globalBhCounter = 0;
			int localRtuCounter = 0, globalRtuCounter = 0;
			int globalRREQsCounter = 0, globalRREPsCounter = 0, globalRERRsCounter = 0, globalNACKsCounter = 0,
					globalCHLsCounter = 0, globalRESsCounter = 0, globalBhTpCounter = 0, globalBhFpCounter = 0;
			int localRREQsCounter = 0, localRREPsCounter = 0, localRERRsCounter = 0, localNACKsCounter = 0,
					localCHLsCounter = 0, localRESsCounter = 0, localBhTpCounter = 0, localBhFpCounter = 0;
			int RREQsCounter = 0, RREPsCounter = 0, RERRsCounter = 0, NACKsCounter = 0, CHLsCounter = 0,
					RESsCounter = 0, blackholeCounterTruePositive = 0, blackholeCounterFalsePositive = 0;
			int previousRREQCounter = 0, previousRREPCounter = 0, previousRERRCounter = 0, previousNACKCounter = 0,
					previousCHLCounter = 0, previousRESCounter = 0, previousBlackholeCounterTruePositive = 0,
					previousBlackholeCounterFalsePositive = 0;
			int globalRtsCounter = 0;
			while ((line = br.readLine()) != null) {
				if (line.equals("<State " + stateCounter + " (controlled)>") || line == "Final state:") {
					line = br.readLine();
					RREQsCounter = 0;
					RREPsCounter = 0;
					RERRsCounter = 0;
					if (modeNAODV() || modeBNAODV()) {
						NACKsCounter = 0;
					}
					if (modeBNAODV()) {
						CHLsCounter = 0;
						RESsCounter = 0;
						blackholeCounterTruePositive = 0;
						blackholeCounterFalsePositive = 0;
					}
					while ((!line.equals("</State " + stateCounter + " (controlled)>") && line != null)) {
						if (line.startsWith("m_")) {
							String metricName = line.substring(0, line.indexOf('='));
							String metricValue = line.substring(line.indexOf('=') + 1);
							if (Program.selectedParameter.contains(metricName)) {
								switch (metricName) {
								case RATE_OF_SUCCESS_PER_RUN:
									hmap.put(metricName, Integer.parseInt(metricValue) - localSuccessCounter);
									localSuccessCounter = Integer.parseInt(metricValue);
									globalSuccessCounter += hmap.get(metricName).intValue();
									break;
								case RATE_OF_SUCCESS_PER_RUN_TRIAL:
									hmap.put(metricName, Integer.parseInt(metricValue) - localTrialCounter);
									localTrialCounter = Integer.parseInt(metricValue);
									globalTrialCounter += hmap.get(metricName).intValue();
									break;
								case ROUTING_TABLE_UPDATE:
									hmap.put(metricName, Integer.parseInt(metricValue) - localRtuCounter);
									localRtuCounter = Integer.parseInt(metricValue);
									globalRtuCounter += hmap.get(metricName).intValue();
									break;
								case ROUTING_TABLE_SIZE:
									hmap.put(metricName, Integer.parseInt(metricValue));
									globalRtsCounter = Integer.parseInt(metricValue);
									break;
								case CONTROL_OVERHEAD:
									hmap.put(metricName, Integer.parseInt(metricValue) - localCoCounter);
									localCoCounter = Integer.parseInt(metricValue);
									globalCoCounter += hmap.get(metricName).intValue();
									break;
								case MALICIOUS_OVERHEAD:
									hmap.put(metricName, Integer.parseInt(metricValue) - localMoCounter);
									localMoCounter = Integer.parseInt(metricValue);
									globalMoCounter += hmap.get(metricName).intValue();
									break;
								case INTERCEPTED_BLACKHOLE:
									hmap.put(metricName, Integer.parseInt(metricValue) - localBhCounter);
									localBhCounter = Integer.parseInt(metricValue);
									globalBhCounter += hmap.get(metricName).intValue();
									break;
								default:
									hmap.put(metricName, null);
								}
							}
						} else if (line.startsWith("messageRREQ")) {
							RREQsCounter++;
						} else if (line.startsWith("messageRREP")) {
							RREPsCounter++;
						} else if (line.startsWith("messageRERR")) {
							RERRsCounter++;
						} else if (line.startsWith("messageNACK") && (modeNAODV() || modeBNAODV())) {
							NACKsCounter++;
						} else if (line.startsWith("messageCHL") && modeBNAODV()) {
							CHLsCounter++;
						} else if (line.startsWith("messageRES") && modeBNAODV()) {
							RESsCounter++;
						} else if (line.startsWith("interceptedBlackhole") && modeBNAODV()) {
							if (line.contains("blackhole")) {
								blackholeCounterTruePositive++;
							} else {
								blackholeCounterFalsePositive++;
							}
						}
						line = br.readLine();
					}

					if (Program.selectedParameter.contains(RATE_OF_SUCCESS_PER_RUN)
							&& Program.selectedParameter.contains(RATE_OF_SUCCESS_PER_RUN_TRIAL)) {
						hmap.put("m_rateSUCCESS", hmap.get(RATE_OF_SUCCESS_PER_RUN));
						hmap.put("m_rateTRIAL", hmap.get(RATE_OF_SUCCESS_PER_RUN_TRIAL));
						if ((int) hmap.get(RATE_OF_SUCCESS_PER_RUN) > 0
								&& (int) hmap.get(RATE_OF_SUCCESS_PER_RUN_TRIAL) > 0) {
							hmap.put(
									"m_rateOfSuccess", Math
											.round(((int) hmap.get(RATE_OF_SUCCESS_PER_RUN) * 1.0
													/ (int) hmap.get(RATE_OF_SUCCESS_PER_RUN_TRIAL)) * 1000.0)
											/ 1000.0);
						} else {
							hmap.put("m_rateOfSuccess", 0);
						}
						hmap.remove(RATE_OF_SUCCESS_PER_RUN);
						hmap.remove(RATE_OF_SUCCESS_PER_RUN_TRIAL);
					}
					if (metricList.contains(CONTROL_OVERHEAD)) {
						hmap.put("m_control_RREQs", previousRREQCounter);
						hmap.put("m_control_RREPs", previousRREPCounter);
						hmap.put("m_control_RERRs", previousRERRCounter);
						if (modeNAODV() || modeBNAODV()) {
							hmap.put("m_control_NACKs", previousNACKCounter);
						}
						if (modeBNAODV()) {
							hmap.put("m_control_CHLs", previousCHLCounter);
							hmap.put("m_control_RESs", previousRESCounter);
						}

						previousRREQCounter = RREQsCounter - localRREQsCounter;
						previousRREPCounter = RREPsCounter - localRREPsCounter;
						previousRERRCounter = RERRsCounter - localRERRsCounter;
						if (modeNAODV() || modeBNAODV()) {
							previousNACKCounter = NACKsCounter - localNACKsCounter;
						}
						if (modeBNAODV()) {
							previousCHLCounter = CHLsCounter - localCHLsCounter;
							previousRESCounter = RESsCounter - localRESsCounter;
						}

						globalRREQsCounter += previousRREQCounter;
						globalRREPsCounter += previousRREPCounter;
						globalRERRsCounter += previousRERRCounter;
						if (modeNAODV() || modeBNAODV()) {
							globalNACKsCounter += previousNACKCounter;
						}
						if (modeBNAODV()) {
							globalCHLsCounter += previousCHLCounter;
							globalRESsCounter += previousRESCounter;
						}

						localRREQsCounter = RREQsCounter;
						localRREPsCounter = RREPsCounter;
						localRERRsCounter = RERRsCounter;
						if (modeNAODV() || modeBNAODV()) {
							localNACKsCounter = NACKsCounter;
						}
						if (modeBNAODV()) {
							localCHLsCounter = CHLsCounter;
							localRESsCounter = RESsCounter;
						}
					}
					if (metricList.contains(INTERCEPTED_BLACKHOLE)) {
						hmap.put("m_intercepted_true_positive", previousBlackholeCounterTruePositive);
						hmap.put("m_intercepted_false_positive", previousBlackholeCounterFalsePositive);

						previousBlackholeCounterTruePositive = blackholeCounterTruePositive - localBhTpCounter;
						previousBlackholeCounterFalsePositive = blackholeCounterFalsePositive - localBhFpCounter;

						globalBhTpCounter += previousBlackholeCounterTruePositive;
						globalBhFpCounter += previousBlackholeCounterFalsePositive;

						localBhTpCounter = blackholeCounterTruePositive;
						localBhFpCounter = blackholeCounterFalsePositive;
					}
					writeLine(stateCounter, bw, metricList, hmap);
					hmap.keySet().removeAll(hmap.keySet());
					stateCounter++;
				}
			}

			// entire simulation values
			bw.write("\ntotal,");
			for (Object object : metricList) {
				if (object.equals(INTERCEPTED_BLACKHOLE) && modeBNAODV()) {
					bw.write(globalBhCounter + ",");
					bw.write(globalBhFpCounter - previousBlackholeCounterFalsePositive + ",");
					bw.write(globalBhTpCounter - previousBlackholeCounterTruePositive + ",");
				} else if (object.equals(ROUTING_TABLE_SIZE)) {
					bw.write(globalRtsCounter + ",");
				} else if (object.equals(CONTROL_OVERHEAD)) {
					bw.write(globalCoCounter + ",");
					if (modeBNAODV()) {
						bw.write(globalCHLsCounter - previousCHLCounter + ",");
					}
					if (modeNAODV() || modeBNAODV()) {
						bw.write(globalNACKsCounter - previousNACKCounter + ",");
					}
					bw.write(globalRERRsCounter - previousRERRCounter + ",");
					if (modeBNAODV()) {
						bw.write(globalRESsCounter - previousRESCounter + ",");
					}
					bw.write(globalRREPsCounter - previousRREPCounter + ",");
					bw.write(globalRREQsCounter - previousRREQCounter + ",");
				} else if (object.equals(MALICIOUS_OVERHEAD) && modeBNAODV()) {
					bw.write(globalMoCounter + ",");
				} else if (object.equals(ROUTING_TABLE_UPDATE)) {
					bw.write(globalRtuCounter + ",");
				} else if (object.equals("m_rateOfSuccess")) {
					bw.write(Math.round((globalSuccessCounter * 1.0 / globalTrialCounter) * 1000.0) / 1000.0 + ",");
					bw.write(globalSuccessCounter + ",");
					bw.write(globalTrialCounter + ",");
				}
			}

			bw.close();
			fw.close();
		}
		
		writeXLSXFile(outputFile.getPath());
	}

	public static void writeLine(int state, BufferedWriter bw, List metricsList, HashMap<String, Number> hmap) {
		try {
			bw.write(state + ",");
			for (Object object : metricsList) {
				bw.write(hmap.get(object) + ",");
			}
			bw.write("\n");
		} catch (IOException e) {
			error(e);
		}
	}

	public static void writeHeader(BufferedWriter bw, List metricsList) {
		try {
			bw.write("run" + ",");
			for (Object object : metricsList) {
				bw.write(object + ",");
			}
			bw.write("\n");
		} catch (IOException e) {
			error(e);
		}
	}

	public static void modelSpecificSetup(int fieldHost, int fieldMobility, int fieldInitMobility,
			int fieldWaitingTime) {
		try {
			BufferedReader file = new BufferedReader(new FileReader(Program.fileName));
			String line;
			StringBuffer inputBuffer = new StringBuffer();

			boolean foundAgent = false;
			while ((line = file.readLine()) != null) {
				if (!foundAgent) {
					if (line.contains("static")) {
						for (int i = 1; i <= fieldHost; i++) {
							inputBuffer.append("\tstatic host" + i + ": Agent");
							inputBuffer.append('\n');
						}
						foundAgent = true;
					} else {
						inputBuffer.append(line);
						inputBuffer.append('\n');
					}
				} else {
					if (!line.contains("static")) {
						if (line.contains("$val <")) {
							inputBuffer.append(line.substring(0, line.indexOf("<") + 2) + fieldMobility
									+ line.substring(line.indexOf(")")));
							inputBuffer.append('\n');
						} else if (line.contains("$rand <")) {
							inputBuffer.append(line.substring(0, line.indexOf("<") + 2) + fieldInitMobility
									+ line.substring(line.indexOf(")")));
							inputBuffer.append('\n');
						} else if (line.contains("waitingTime(self, $dest) :=")) {
							inputBuffer.append(line.substring(0, line.indexOf('=') + 2) + fieldWaitingTime);
							inputBuffer.append('\n');
						} else {
							inputBuffer.append(line);
							inputBuffer.append('\n');
						}

					}
				}
			}
			String inputStr = inputBuffer.toString();
			file.close();

			FileOutputStream fileOut = new FileOutputStream(Program.fileName);
			fileOut.write(inputStr.getBytes());
			fileOut.close();
		} catch (Exception e) {
			error(e);
		}
	}

	public static void bnaodvSpecificSetup(int fieldHost, int fieldBlackhole, int fieldColluder, int fieldMobility,
			int fieldInitMobility, int fieldWaitingTime, int fieldSeqNumStep, int fieldSeqNumDefault) {
		try {
			BufferedReader file = new BufferedReader(new FileReader(Program.fileName));
			String line;
			StringBuffer inputBuffer = new StringBuffer();

			boolean foundAgent = false;
			while ((line = file.readLine()) != null) {
				if (!foundAgent) {
					if (line.contains("static")) {
						for (int i = 1; i <= fieldBlackhole; i++) {
							inputBuffer.append("\tstatic blackhole" + i + ": Blackhole");
							inputBuffer.append('\n');
						}
						for (int i = 1; i <= fieldColluder; i++) {
							inputBuffer.append("\tstatic colluder" + i + ": Colluder");
							inputBuffer.append('\n');
						}
						for (int i = 1; i <= fieldHost; i++) {
							inputBuffer.append("\tstatic host" + i + ": Host");
							inputBuffer.append('\n');
						}
						foundAgent = true;
					} else {
						inputBuffer.append(line);
						inputBuffer.append('\n');
					}
				} else {
					if (!line.contains("static")) {
						if (line.contains("$val <")) {
							inputBuffer.append(line.substring(0, line.indexOf('<') + 2) + fieldMobility
									+ line.substring(line.indexOf(')')));
							inputBuffer.append('\n');
						} else if (line.contains("$rand <")) {
							inputBuffer.append(line.substring(0, line.indexOf("<") + 2) + fieldInitMobility
									+ line.substring(line.indexOf(")")));
							inputBuffer.append('\n');
						} else if (line.contains("waitingTime(self, $dest) :=")) {
							inputBuffer.append(line.substring(0, line.indexOf('=') + 2) + fieldWaitingTime);
							inputBuffer.append('\n');
						} else if (line.contains("waitingTime($rrep) <")) {
							inputBuffer.append(line.substring(0, line.indexOf('<') + 2) + fieldWaitingTime
									+ line.substring(line.lastIndexOf(')')));
							inputBuffer.append('\n');
						} else if (line.contains("lastKnownDestSeqNum(self,dest($m)) +")) {
							inputBuffer.append(line.substring(0, line.indexOf('+') + 2) + fieldSeqNumStep + ",");
							inputBuffer.append('\n');
						} else if (line.contains("maxKnownDestSeqNum(self) :=") && !line.contains("$")) {
							inputBuffer.append(line.substring(0, line.indexOf('=') + 2) + fieldSeqNumDefault);
							inputBuffer.append('\n');
						} else {
							inputBuffer.append(line);
							inputBuffer.append('\n');
						}

					}
				}
			}
			String inputStr = inputBuffer.toString();
			file.close();

			FileOutputStream fileOut = new FileOutputStream(Program.fileName);
			fileOut.write(inputStr.getBytes());
			fileOut.close();
		} catch (Exception e) {
			error(e);
		}
	}

	public static boolean modeAODV() {
		return Program.choice.getSelectedItem().equals("AODV");
	}

	public static boolean modeNAODV() {
		return Program.choice.getSelectedItem().equals("N-AODV");
	}

	public static boolean modeBNAODV() {
		return Program.choice.getSelectedItem().equals("BN-AODV");
	}

	/**
	 * <p>
	 * Metodo per il recupero delle informazioni relative alla topologia di rete
	 * corrente
	 * </p>
	 */
	public static Map<Integer, Map<Integer, List<String>>> loadTopologyInfo(String fileName, String searchFilter)
			throws IOException {

		/**
		 * Mappa Host - Insieme di valori
		 */
		Map<Integer, List<String>> map1 = new HashMap<>();
		/**
		 * Mappa Stato - Host
		 */
		Map<Integer, Map<Integer, List<String>>> map2 = new HashMap<>();

		try (FileReader in = new FileReader(fileName); BufferedReader br = new BufferedReader(in)) {
			String line;
			String messageContent;
			String messageType;
			String neighbor;
			List<String> list;
			int equalIndex;
			int hostId;
			int stateCounter = 1;
			while ((line = br.readLine()) != null) {
				if (line.equals("<State " + stateCounter + " (controlled)>") || line == "Final state:") {
					line = br.readLine();
					while (!line.equals("</State " + stateCounter + " (controlled)>")) {
						// selection criteria
						if (line.startsWith(searchFilter)) {
							if (searchFilter.equals("message") && !line.contains("messageType")) {
								list = new ArrayList<>();
								equalIndex = line.indexOf('=');
								hostId = Integer.parseInt(line.substring(equalIndex + 6, line.indexOf(',')));
								messageType = line.substring(searchFilter.length(), line.indexOf('('));
								messageContent = messageType.concat(",")
										.concat(line.substring(equalIndex + 6, line.length() - 1));
								list.add(messageContent.replaceAll("host", ""));
								map1.put(hostId, list);
								System.out.println(stateCounter + " " + hostId + " " + list);
								map2.put(stateCounter, map1);
							} else if (searchFilter.equals("isLinked")) {
								list = new ArrayList<>();
								line = line.replaceAll("host", "").replaceAll("isLinked", "");
								equalIndex = line.indexOf('=');
								if ("true".equals(line.substring(equalIndex + 1))) {
									hostId = Integer.parseInt(line.substring(line.indexOf('(') + 1, line.indexOf(',')));
									neighbor = line.substring(line.indexOf(',') + 1, line.indexOf(')'));
									if (map1.containsKey(hostId)) {
										list = map1.get(hostId);
										map1.remove(hostId);
									}
									list.add(neighbor);
									map1.put(hostId, list);
									// System.out.println(stateCounter + " " + hostId + " " + list);

									if (map2.containsKey(stateCounter)) {
										map2.remove(stateCounter);
									}
									map2.put(stateCounter, map1);
								}
							}
						}
						line = br.readLine();
					}
					stateCounter++;
					map1 = new HashMap<>(); // testare questa modifica per i message
				}
			}
		}
		return map2;
	}

	public static void main(String[] args) throws IOException {
		loadTopologyInfo(System.getProperty("user.dir") + "\\result\\log\\result.txt", "message");
	}

}
