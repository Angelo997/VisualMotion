package it.uniba.di.parser;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

import it.uniba.di.application.Executor;
import it.uniba.di.support.Utility;

public class AsmetaLogParser extends Utility {

	public static final String ASMETA_EQUAL = ":=";
	public static final String ASMETA_VARIABLE = "$_";
	public static final String ASMETA_PARALLEL_BLOCK_BEGIN = "par";
	public static final String ASMETA_PARALLEL_BLOCK_END = "endpar";

	public static final String NEW_LINE = System.getProperty("line.separator");
	public static final String TAB_3 = "\t\t\t";
	public static final String TAB_4 = "\t\t\t\t";
	public static final String TAB_5 = "\t\t\t\t\t";

	private static Map<Integer, Map<Integer, Boolean>> neighborsMap;
	static {
		neighborsMap = new HashMap<>();
	}

	private static void mobilityModel(int run, int ASM_NUM, int CONNECTION_PROBABILITY, StringBuilder stringBuilder) {
		if (run == 1) {
			for (int i = 1; i <= ASM_NUM; i++) {
				neighborsMap.put(i, new HashMap<>());
			}
		}
		for (int i = 1; i <= ASM_NUM; i++) {
			for (int j = 1; j <= ASM_NUM; j++) {
				if (i != j) {
					if (!neighborsMap.get(i).containsKey(j)) {
						if (neighborsMap.get(j).containsKey(i)) {
							neighborsMap.get(i).put(j, neighborsMap.get(j).get(i));
						} else {
							neighborsMap.get(i).put(j, new Random().nextBoolean());
						}
						stringBuilder.append(TAB_4 + "isLinked(host" + i + ",host" + j + ")" + ASMETA_EQUAL
								+ neighborsMap.get(i).get(j) + NEW_LINE);
					} else {
						if (new Random().nextInt(100) < CONNECTION_PROBABILITY && i < j) {
							neighborsMap.get(i).replace(j, !neighborsMap.get(i).get(j));
							neighborsMap.get(j).replace(i, !neighborsMap.get(j).get(i));
							stringBuilder.append(TAB_4 + "isLinked(host" + i + ",host" + j + ")" + ASMETA_EQUAL
									+ neighborsMap.get(i).get(j) + NEW_LINE);
							stringBuilder.append(TAB_4 + "isLinked(host" + j + ",host" + i + ")" + ASMETA_EQUAL
									+ neighborsMap.get(j).get(i) + NEW_LINE);
						}
					}
				}
			}
		}
	}

	public static void extractLog(int run, int ASM_NUM, int CONNECTION_PROBABILITY) throws IOException {
		Map<String, String> msgStringBuilder = new HashMap<>();

		StringBuilder stringBuilder = new StringBuilder();
		if (run == 1) {
			stringBuilder.append(TAB_3 + "forall " + ASMETA_VARIABLE + "a in Agent do" + NEW_LINE 					
					+ TAB_4 + ASMETA_PARALLEL_BLOCK_BEGIN + NEW_LINE + TAB_5 + "curSeqNum(" + ASMETA_VARIABLE + "a)" + ASMETA_EQUAL + "0"
					+ NEW_LINE + TAB_5 + "localReqCount(" + ASMETA_VARIABLE + "a)" + ASMETA_EQUAL + "0" + NEW_LINE
					+ TAB_5 + "receivedReq(" + ASMETA_VARIABLE + "a)" + ASMETA_EQUAL + "[]" + NEW_LINE + 
					TAB_4 + "forall " + ASMETA_VARIABLE + "d in Agent do" + NEW_LINE +
				    TAB_5 + "waitingForRouteTo(" + ASMETA_VARIABLE + "a," + ASMETA_VARIABLE + "d)" + ASMETA_EQUAL + "false" + NEW_LINE
					+ TAB_4 + ASMETA_PARALLEL_BLOCK_END + NEW_LINE);
			stringBuilder.append(TAB_3 + ASMETA_PARALLEL_BLOCK_BEGIN + NEW_LINE);
			mobilityModel(run, ASM_NUM, CONNECTION_PROBABILITY, stringBuilder);
			stringBuilder.append(TAB_3 + ASMETA_PARALLEL_BLOCK_END + NEW_LINE);
		} else {
			try (FileReader in = new FileReader(new File(Executor.RESULT_OUTPUT_FILE));
					BufferedReader br = new BufferedReader(in)) {
				if (Parser.modeAODV()) {
					String line;
					boolean foundMobilityBlock = false;
					while ((line = br.readLine()) != null && !line.contains("</State 1 (controlled)>")) {
						if (line.startsWith("curSeqNum") || line.startsWith("lastKnownDestSeqNum")
								|| line.startsWith("localReqCount") || line.startsWith("receivedReq")
								|| line.startsWith("waitingForRouteTo")) {
							stringBuilder.append(TAB_4 + line.replace("=", ASMETA_EQUAL).concat(NEW_LINE));
						} else if (line.startsWith("isLinked") && !foundMobilityBlock) {
							mobilityModel(run, ASM_NUM, CONNECTION_PROBABILITY, stringBuilder);
							foundMobilityBlock = true;
						} else if (line.startsWith("requests")) {
							line = line.replace("Message!", ASMETA_VARIABLE).replace("=", ASMETA_EQUAL)
									.concat(NEW_LINE);
							String key = line.substring(line.indexOf(ASMETA_VARIABLE), line.indexOf(','));
							if (msgStringBuilder.get(key) != null) {
								msgStringBuilder.replace(key, msgStringBuilder.get(key) + TAB_5 + line);
							}
						} else if (line.startsWith("messageRREQ") || line.startsWith("messageRREP")
								|| line.startsWith("messageRERR") || line.startsWith("messageType")) {
							line = line.replace("Message!", ASMETA_VARIABLE).replace("=", ASMETA_EQUAL)
									.concat(NEW_LINE);
							String key = line.substring(line.indexOf(ASMETA_VARIABLE), line.indexOf(')'));
							if (msgStringBuilder.get(key) != null) {
								msgStringBuilder.replace(key, msgStringBuilder.get(key) + TAB_5 + line);
							}
						} else if (line.startsWith("isConsumed") && line.endsWith("false")) { // prima occorrenza di
																								// ASMETA_VARIABLE
							line = line.replace("Message!", ASMETA_VARIABLE).replace("=", ASMETA_EQUAL)
									.concat(NEW_LINE);
							String key = line.substring(line.indexOf(ASMETA_VARIABLE), line.indexOf(','));
							String initBlock = NEW_LINE + NEW_LINE + TAB_4 + "extend Message with " + key + " do "
									+ NEW_LINE + TAB_4 + ASMETA_PARALLEL_BLOCK_BEGIN + NEW_LINE + TAB_5 + line;
							msgStringBuilder.put(key, initBlock);

							String tmstmp = line.substring(line.indexOf(',') + 1, line.indexOf(')'));
							String randomKey = ASMETA_VARIABLE + new Random().nextInt(100000);
							stringBuilder.append(TAB_4 + "extend Time with " + randomKey + " do" + NEW_LINE + TAB_5
									+ "set(" + randomKey + ")" + ASMETA_EQUAL + tmstmp + NEW_LINE);
						} else {
							// System.out.println(line);
						}
					}
				}
			}
		}
		for (Map.Entry<String, String> msg : msgStringBuilder.entrySet()) {
			msg.setValue(msg.getValue() + TAB_4 + ASMETA_PARALLEL_BLOCK_END);
			stringBuilder.append(msg.getValue());
		}
		System.out.println(stringBuilder);
	}

	public static void contextPut() throws IOException {
		if (Parser.modeAODV()) {
			/*try {
				BufferedReader file = new BufferedReader(new FileReader(Program.fileName));
				String line;
				StringBuffer inputBuffer = new StringBuffer();

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
				Program.progressList.add("ERROR: Problem reading file.");
				Program.progressList.select(Program.progressList.getItemCount() - 1);
			}*/
		}
	}
}
