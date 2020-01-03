package restinterface.resources;

public class Negocio{
	private String client_offer;
	private String fab;
	private String prod;
	private int price;
	private int amount;

	public Negocio(String client_offer, String fab, String prod, int price, int amount){
		this.fab = fab;
		this.client_offer = client_offer;
		this.prod = prod;
		this.price = price;
		this.amount = amount;
	}
}