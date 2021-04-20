package it.uniba.di.support;

import java.util.concurrent.ThreadLocalRandom;

import it.uniba.di.parser.AODVParser;
import it.uniba.di.support.structures.ConnectivityMatrix;

/**
 * Created by pmarc on 18/02/2019.
 */
public class MobilityModel {

	/**
	 * 
	 * @param probability
	 * @param hostNumber
	 * @param connectivityMatrix
	 * @return
	 */
	public static String initConnectivity(int probability, int hostNumber,
			ConnectivityMatrix<Boolean> connectivityMatrix) {
		StringBuilder sb = new StringBuilder();
		System.out.println("Init hosts:" + hostNumber);
		for (int i = 0; i < hostNumber; i++) {
			for (int j = i + 1; j < hostNumber && j != i; j++) {
				int local_probability = ThreadLocalRandom.current().nextInt(0, 100);
				if (local_probability < probability) {
					sb.append(AODVParser.TAB_3 + "isLinked(host" + (i + 1) + ",host" + (j + 1) + "):=true\n");
					sb.append(AODVParser.TAB_3 + "isLinked(host" + (j + 1) + ",host" + (i + 1) + "):=true\n");
					connectivityMatrix.insert(i, j, true);
				}
			}
		}
		return sb.toString();
	}

	/**
	 * 
	 * @param probability
	 * @param hostNumber
	 * @param connectivityMatrix
	 * @return
	 */
	public static String mobilitySetup(int probability, int hostNumber,
			ConnectivityMatrix<Boolean> connectivityMatrix) {
		StringBuilder sb = new StringBuilder();
		System.out.println("Move hosts:" + hostNumber);

		for (int i = 0; i < hostNumber; i++) {
			for (int j = i + 1; j < hostNumber && j != i; j++) {
				int local_probability = ThreadLocalRandom.current().nextInt(0, 100);
				if (local_probability < probability) {
					boolean value = !connectivityMatrix.get(i, j);
					connectivityMatrix.insert(i, j, value);
				}
				if (connectivityMatrix.get(i, j)) {
					sb.append(AODVParser.TAB_3 + "isLinked(host" + (i + 1) + ",host" + (j + 1) + "):=true\n");
					sb.append(AODVParser.TAB_3 + "isLinked(host" + (j + 1) + ",host" + (i + 1) + "):=true\n");
				}
			}
		}
		return sb.toString();
	}

	/**
	 * 
	 * @param hostNumber
	 * @param connectivityMatrix
	 * @return
	 */
	public static String getIsLinked(int hostNumber, ConnectivityMatrix<Boolean> connectivityMatrix) {
		StringBuilder sb = new StringBuilder();
		System.out.println("Require isLinked for hosts:" + hostNumber);

		for (int i = 0; i < hostNumber; i++) {
			for (int j = i + 1; j < hostNumber && j != i; j++) {
				if (connectivityMatrix.get(i, j)) {
					sb.append(AODVParser.TAB_3 + "isLinked(host" + (i + 1) + ",host" + (j + 1) + "):=true\n");
					sb.append(AODVParser.TAB_3 + "isLinked(host" + (j + 1) + ",host" + (i + 1) + "):=true\n");
				}
			}
		}
		return sb.toString();
	}
}
