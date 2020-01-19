package main.java.restinterface.resources;

import java.net.*;
import java.io.*;
import java.util.ArrayList;
import java.util.List;

import main.java.terminal.ReadMessage;
import main.proto.Protos.Syn;
import main.proto.Protos.NegSyn;
import main.proto.Protos.Dropwizard;
import main.proto.Protos.ResponseProdutoDropwizard;
import main.proto.Protos.Production;
import main.proto.Protos.ResponseImporterDropwizard;
import main.proto.Protos.ImporterDropwizard;
import main.proto.Protos.ResponseNegotiationDropwizard;
import main.proto.Protos.NegotiationDropwizard;

public class AskServer{
	public List<Production> askServerProduto(String name) 
	throws IOException, InterruptedException, SocketException{

        System.out.println("Entrei no askServerProduto");
		int port = getPort(name);
		System.out.println(port);
		Socket cs = new Socket("127.0.0.1", port);
		System.out.println("Liguei-me à porta " + port);


		OutputStream out = cs.getOutputStream();
		BufferedReader teclado = new BufferedReader(new InputStreamReader(System.in));
		ReadMessage rm = new ReadMessage(cs);

		//Envia o Syn
		NegSyn syn = NegSyn.newBuilder().
						setType(NegSyn.OpType.DROP).
						build();
		
		byte[] send = syn.toByteArray();
		out.write(send);
		System.out.println("Enviei o Syn");
		//Envia o pedido
		Dropwizard drop = Dropwizard.newBuilder().
							setType(Dropwizard.DropType.PROD).
							setUsername(name).
							setProd("PSD").
							build();
		
		byte[] req = drop.toByteArray();
		out.write(req);
		System.out.println("Enviei tudo " + name);
		//Recebe o pedido
		byte[] receive = rm.receiveMessage();
		ResponseProdutoDropwizard rdp = ResponseProdutoDropwizard.parseFrom(receive);

		System.out.println("Shutdown Output");

		cs.shutdownOutput();
		teclado.close();

		return rdp.getProductsList();

	}

	public List<NegotiationDropwizard> askServerNegocio(String name, String prod) 
	throws IOException, InterruptedException, SocketException{

		int port = getPort(name);
		Socket cs = new Socket("127.0.0.1", port);

		System.out.println("Liguei-me à porta " + port);

		OutputStream out = cs.getOutputStream();
		BufferedReader teclado = new BufferedReader(new InputStreamReader(System.in));
		ReadMessage rm = new ReadMessage(cs);

		System.out.println("Vou enviar o syn");
		//Envia o Syn
		NegSyn syn = NegSyn.newBuilder().
						setType(NegSyn.OpType.DROP).
						build();
		
		byte[] send = syn.toByteArray();
		out.write(send);
		
		System.out.println("Vou enviar o pedido");
		//Envia o pedido
		Dropwizard drop = Dropwizard.newBuilder().
							setType(Dropwizard.DropType.NEG).
							setUsername(name).
							setProd(prod).
							build();
		
		byte[] req = drop.toByteArray();
		out.write(req);

		System.out.println("Estou à espera");
		//Recebe o pedido
		byte[] receive = rm.receiveMessage();
		ResponseNegotiationDropwizard rdp = ResponseNegotiationDropwizard.parseFrom(receive);

		System.out.println("Shutdown Output");

		cs.shutdownOutput();
		teclado.close();

		return rdp.getNegotiationList();
	}

	public List<ImporterDropwizard> askServersImportador(String name) throws IOException{
		List<ImporterDropwizard> res = new ArrayList<>();
		int []ports = new int[3];
		ports[0] = 9998;
		ports[1] = 9997;
		ports[2] = 9996;
		try{
			for(int i: ports){
				List<ImporterDropwizard> askServer = askServerImportador(name, i);
				res.addAll(askServer);
			}
		}
		catch(Exception exc){}
		return res;
	}

	public List<ImporterDropwizard> askServerImportador(String name, int port) 
	throws IOException, InterruptedException, SocketException{

		Socket cs = new Socket("127.0.0.1", port);

		OutputStream out = cs.getOutputStream();
		BufferedReader teclado = new BufferedReader(new InputStreamReader(System.in));
		ReadMessage rm = new ReadMessage(cs);

		//Envia o Syn
		NegSyn syn = NegSyn.newBuilder().
						setType(NegSyn.OpType.DROP).
						build();
		
		byte[] send = syn.toByteArray();
		out.write(send);
		
		//Envia o pedido
		Dropwizard drop = Dropwizard.newBuilder().
							setType(Dropwizard.DropType.IMP).
							setUsername(name).
							setProd("").
							build();
		
		byte[] req = drop.toByteArray();
		out.write(req);

		//Recebe o pedido
		byte[] receive = rm.receiveMessage();
		ResponseImporterDropwizard rdp = ResponseImporterDropwizard.parseFrom(receive);

		System.out.println("Shutdown Output");

		cs.shutdownOutput();
		teclado.close();

		return rdp.getImporterList();
	}

	public int getPort(String name){
		char first = name.charAt(0);
		int ascii = (int) first;
		int port = 9998;

		if(ascii >= 60 && ascii <= 90){
			port = 9998;
		}
		else if(ascii >= 97 && ascii <= 122){
			port = 9997;
		}
		else {
			port = 9996;
		}
		return port;
	}
}