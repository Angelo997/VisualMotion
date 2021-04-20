package it.uniba.di.support;

import java.io.BufferedReader;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.util.Arrays;

import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;

import it.uniba.di.application.Program;

/**
 * 
 * <p>
 * Questa classe raccoglie tutti i metodi che vengono richiamati nel programma
 * principale per eseguire azioni ripetitive.
 * </p>
 *
 */
public class Utility {

	/**
	 * <p>
	 * Riferimento alla directory contenente i log ASMETA.
	 * </p>
	 */
	protected static final String ASMETA_LOG_PATH = "result\\log\\";

	/**
	 * Logger
	 */
	public static final Logger logger = Logger.getLogger(Utility.class);
	static {
		DOMConfigurator.configure("conf/log4j.xml");
		debug("MOTION started with success");
	}

	/**
	 * <p>
	 * Constructor
	 * </p>
	 */
	public Utility() {
	}

	/**
	 * 
	 * @param msg
	 */
	public static void debug(String msg) {
		StackTraceElement[] stacktrace = Thread.currentThread().getStackTrace();
		StackTraceElement e = stacktrace[2];
		logger.debug("[" + e.getClassName() + "] [" + e.getMethodName() + "] - " + msg);
	}

	/**
	 * 
	 * @param ex
	 */
	public static void error(Exception ex) {
		logger.error(Arrays.toString(ex.getStackTrace()));
	}

	/**
	 * 
	 * @param info
	 */
	public static void displayInfo(String info) {
		Program.progressList.add(info);
		scrollProgressList();
	}
	
	/**
	 * 
	 */
	private static void scrollProgressList() {
		Program.progressList.select(Program.progressList.getItemCount() - 1);
	}

	/**
	 * 
	 * @param csvFile
	 */
	public static void writeXLSXFile(String csvFile) {
		Workbook workBook = null;
		Row currentRow;
		FileOutputStream fileOutputStream = null;

		try (BufferedReader br = new BufferedReader(new FileReader(csvFile))) {
			String xlsxFileAddress = csvFile.replace("csv", "xlsx");
			workBook = new HSSFWorkbook();
			Sheet sheet = workBook.createSheet("sheet1");
			String currentLine = null;
			int rowNum = 0;
			while ((currentLine = br.readLine()) != null) {
				String str[] = currentLine.split(",");
				rowNum++;
				currentRow = sheet.createRow(rowNum);
				for (int i = 0; i < str.length; i++) {
					currentRow.createCell(i).setCellValue(str[i]);
				}
			}
			fileOutputStream = new FileOutputStream(xlsxFileAddress);
			workBook.write(fileOutputStream);
			fileOutputStream.close();
		} catch (Exception ex) {
			error(ex);
		} finally {
			try {
				if (workBook != null) {
					workBook.close();
				}
			} catch (IOException e) {
				error(e);
			}

			try {
				if (fileOutputStream != null) {
					fileOutputStream.close();
				}
			} catch (IOException e) {
				error(e);
			}
		}
	}

}
